## Steps for running R tutorial in CyVerse discovery environment:

To run neon_spectral_signatures_full_SJER.R in the CyVerse NEON community discovery RStudio environment:

  1. login to CyVerse discovery (de.cyverse.org/de), join NEON community folder (Apps > My Apps > My Communities > NEON)
  2. launch RStudio Geospatial Latest container
  3. open the terminal tab, clone the foss_project repo (and optionally the neon-shiny-browser repo) into local directory
  ```
  git clone https://github.com/bridgethass/foss_project.git
  git clone https://github.com/cyverse-gis/neon-shiny-browser
  ``` 
  4. initialize irods & add credentials
  ```
  iinit
  host name (DNS) of server to connect to: data.cyverse.org
  port number: 1247
  irods user name: bridgethass
  irods zone: iplant
  password
  ```
  5. use `iget` to move h5 and tif teaching files from istore to local "./data" director **TO DO - ADD THESE FILES TO NEON COMMUNITY FOLDER FOR ALL TO ACCESS**
  ```
  iget /iplant/home/bridgethass/sci_data/NEON_D17_SJER_DP3_257000_4112000_reflectance.h5 ./data/NEON_D17_SJER_DP3_257000_4112000_reflectance.h5
  iget /iplant/home/bridgethass/sci_data/NEON_hyperspectral_tutorial_SJER_RGB_stack.tif ./data/NEON_hyperspectral_tutorial_SJER_RGB_stack.tif
  ```
  6. now from the r folder inside foss_project you can run the r file, note that there is an interactive component requiring the user to click different parts of the spectral image
  7. commit any changes made to the r file as follows - first configure git on this container 
  ```
  git config --global user.email "bridgethass@gmail.com"
  git config --global user.name "bridgethass"
  git status
  git add neon_spectral_signatures_full_SJER.R
  git status 
  git commit -m "modified data paths to read in data from cyverse local directory"
  git push
  ```
