# Load required packages
library(rhdf5)
library(reshape2)
library(raster)
library(plyr)
library(ggplot2)

## Download two datasets from:

# 1) https://www.dropbox.com/s/ukdfy5uj35loq0z/NEON_hyperspectral_tutorial_example_subset.h5?dl=0
# 2) https://www.dropbox.com/s/uuqexlomeimlweu/NEON_hyperspectral_tutorial_example_RGB_stack_image.tif?dl=0

# set working directory to ensure R can find the file we wish to import and where
# we want to save our files. Be sure to move the download into your working directory!
wd="./data/" #This will depend on your local environment
setwd(wd)

# define filepath to the hyperspectral dataset
# f <- paste0(wd,"NEON_D17_SJER_DP3_257000_4112000_reflectance.h5")
sjer_h5 = "/home/rstudio/foss_project/r/data/NEON_D17_SJER_DP3_257000_4112000_reflectance.h5"
sjer_tif = "/home/rstudio/foss_project/r/data/NEON_hyperspectral_tutorial_SJER_RGB_stack.tif"

# read in the wavelength information from the HDF5 file
wavelengths <- h5read(sjer_h5,"/SJER/Reflectance/Metadata/Spectral_Data/Wavelength")

# grab scale factor from the Reflectance attributes
reflInfo<- h5readAttributes(sjer_h5,"/SJER/Reflectance/Reflectance_Data" )

scaleFact = reflInfo$Scale_Factor

# Read in RGB image as a 'stack' rather than a plain 'raster'
# rgbStack <- stack(paste0(wd,"NEON_hyperspectral_tutorial_SJER_RGB_stack.tif"))
rgbStack <- stack(sjer_tif)

## Plot as RGB image
plotRGB(rgbStack,
        r=1,g=2,b=3, scale=300, 
        stretch = "lin")

# change plotting parameters to better see the points and numbers generated from clicking
par(col="red", cex=3)

# ## Interactive `click` function from `raster` package
# Next, we use an interactive clicking function to identify the pixels that we want
# to extract spectral signatures for. To follow along best with this tutorial, we 
# suggest the following five cover types (exact location shown below). 
# 1. Irrigated grass
# 2. Tree canopy (avoid the shaded northwestern side of the tree)
# 3. Roof
# 4. Bare soil (infield)
# 5. Open water

# use the 'click' function
c=click(rgbStack, id=T, xy=T, cell=T, type="p", pch=16, col="magenta", col.lab="red")
## Hit ESC after selecting five points


# convert cell number to row and column
c$row=c$cell%/%nrow(rgbStack)+1
c$col=c$cell%%ncol(rgbStack)


## Extract spectral signatures
#first, create a new data.frame of wavelengths
Pixel_df=as.data.frame(wavelengths)

# loop through each of the cells that we selected
for(i in 1:length(c$cell)){
  
  # extract Spectra from a single pixel
  aPixel <- h5read(f,"/SJER/Reflectance/Reflectance_Data",
                   index=list(NULL,c$col[i],c$row[i]))
  
  # scale reflectance values from 0-1
  aPixel=aPixel/as.vector(scaleFact)
  
  # reshape the data and turn into dataframe
  b <- adply(aPixel,c(1))
  
  # rename the column that we just created
  names(b)[2]=paste0("Point_",i)
  
  # add reflectance values for this pixel to our combined data.frame
  Pixel_df=cbind(Pixel_df,b[2])
}

## Plot spectral signatures
# Use the melt() funciton to reshape the dataframe into a format that ggplot prefers
Pixel.melt=melt(Pixel_df, id.vars = "wavelengths", value.name = "Reflectance")

ggplot()+
  geom_line(data = Pixel.melt, mapping = aes(x=wavelengths, y=Reflectance, color=variable), lwd=1.5)+
  scale_colour_manual(values = c("green2", "green4", "grey50","tan4","blue3"),
                      labels = c("Field", "Tree", "Roof","Soil","Water"))+
  labs(color = "Cover Type")+
  ggtitle("Land cover spectral signatures")+
  theme(plot.title = element_text(hjust = 0.5, size=20))+
  xlab("Wavelength")

# Nice! However, there seems to be something weird going on in the wavelengths near 1400nm and 1850 nm...
# 
# ## Atmospheric Absorbtion Bands 
# Those irregularities around 1400nm and 1850 nm are two major atmospheric absorbtion bands - regions
# where gasses in the atmosphere (primarily carbon dioxide and water vapor) absorb radiation, and 
# therefore, obscure the reflected radiation that the imaging spectrometer measures. Fortunately, the 
# lower and upper bound of each of those atmopheric absopbtion bands is specified in the HDF5 file. 
# Let's read those bands and plot rectangles where the reflectance measurements are obscured by 
# atmospheric absorbtion. 

# grab Reflectance metadata (which contains absorption band limits)
reflMetadata<- h5readAttributes(f,"/SJER/Reflectance" )

ab1 = reflMetadata$Band_Window_1_Nanometers
ab2 = reflMetadata$Band_Window_2_Nanometers

## Plot spectral signatures again with rectangles showing the absorption bands
ggplot()+
  geom_line(data = Pixel.melt, mapping = aes(x=wavelengths, y=Reflectance, color=variable), lwd=1.5)+
  geom_rect(mapping=aes(ymin=min(Pixel.melt$Reflectance),ymax=max(Pixel.melt$Reflectance), xmin=ab1[1], xmax=ab1[2]), color="black", fill="grey40", alpha=0.8)+
  geom_rect(mapping=aes(ymin=min(Pixel.melt$Reflectance),ymax=max(Pixel.melt$Reflectance), xmin=ab2[1], xmax=ab2[2]), color="black", fill="grey40", alpha=0.8)+
  scale_colour_manual(values = c("green2", "green4", "grey50","tan4","blue3"),
                      labels = c("Field", "Tree", "Roof","Soil","Water"))+
  labs(color = "Cover Type")+
  ggtitle("Land cover spectral signatures")+
  theme(plot.title = element_text(hjust = 0.5, size=20))+
  xlab("Wavelength")

# Now we can clearly see that the noisy sections of each spectral signature is within the atmospheric
# absorbtion bands. For our final step, let's take all reflectance values from within each absorbtion
# band and set them to `NA` to remove the noisy sections from the plot.

# Duplicate the spectral signatures into a new data.frame
Pixel.melt.masked=Pixel.melt

# Mask out all values within each of the two atmospheric absorbtion bands
Pixel.melt.masked[Pixel.melt.masked$wavelengths>ab1[1]&Pixel.melt.masked$wavelengths<ab1[2],]$Reflectance=NA
Pixel.melt.masked[Pixel.melt.masked$wavelengths>ab2[1]&Pixel.melt.masked$wavelengths<ab2[2],]$Reflectance=NA

# Plot the masked spectral signatures
ggplot()+
  geom_line(data = Pixel.melt.masked, mapping = aes(x=wavelengths, y=Reflectance, color=variable), lwd=1.5)+
  scale_colour_manual(values = c("green2", "green4", "grey50","tan4","blue3"),
                      labels = c("Field", "Tree", "Roof","Soil","Water"))+
  labs(color = "Cover Type")+
  ggtitle("Land cover spectral signatures")+
  theme(plot.title = element_text(hjust = 0.5, size=20))+
  xlab("Wavelength")

