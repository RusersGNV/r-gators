library(raster)
library(rgdal)

dir.create('data',showWarnings = F)
download.file('https://ndownloader.figshare.com/files/3701578','data/NEONDSAirborneRemoteSensing.zip')
unzip('data/NEONDSAirborneRemoteSensing.zip', exdir = 'data')

####################################3
# Part 1, learning about rasters
# Load the first raster into R

DSM_HARV <- raster("data/NEON-DS-Airborne-Remote-Sensing/HARV/DSM/HARV_dsmCrop.tif")

# Plot the raster

# Look at the raster's metadata

# Look at the raster's CRS


# Look at the rasters extent




###########################
# Part 2, more advanced plotting

# Plot with a title


# Plot using predifined breaks


# Layering two rasters together

DSM_hill_HARV <-  raster("data/NEON-DS-Airborne-Remote-Sensing/HARV/DSM/HARV_DSMhill.tif")

###########################
# Part 3, reprojecting raster data

# Reload the rasters
rm(DSM_HARV, DSM_hill_HARV)

# import DTM
DTM_HARV <- raster("data/NEON-DS-Airborne-Remote-Sensing/HARV/DTM/HARV_dtmCrop.tif")
# import DTM hillshade
DTM_hill_HARV <- raster("data/NEON-DS-Airborne-Remote-Sensing/HARV/DTM/HARV_DTMhill_WGS84.tif")


# Plot both together


#########################
# Part 4, raster calculations

# load the DTM & DSM rasters
DTM_HARV <- raster("data/NEON-DS-Airborne-Remote-Sensing/HARV/DTM/HARV_dtmCrop.tif")
DSM_HARV <- raster("data/NEON-DS-Airborne-Remote-Sensing/HARV/DSM/HARV_dsmCrop.tif")

########################
# Part 5, working with different bands

rm(DTM_HARV, DSM_HARV)

RGB_band1_HARV <-
  raster("data/NEON-DS-Airborne-Remote-Sensing/HARV/RGB_Imagery/HARV_RGB_Ortho.tif")

plot(RGB_band1_HARV)
