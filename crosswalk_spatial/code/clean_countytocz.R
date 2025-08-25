library(data.table)
library(readxl)
library(readxl)
library(dplyr)
library(stringr)
library(sf)
library(ggplot2)

rm(list=ls())
rootdir <- "~/Dropbox/publicdata/"

# ===================================
# Merge county to CZ crosswalk onto zip to county crosswalk
# ===================================
# Read in 2022 unique zip to county crosswalk (last available)
ziptocounty <- fread(paste0(rootdir,"crosswalk_spatial/output/ziptocounty_2022.csv"))

# Read in county to CZ shapefile 2010 
shape_data10 <- st_read(paste0(rootdir,"shapefiles/counties_cz/County-Shapes-2010-1147att/counties10.shp"))

# Read in county to CZ shapefile 2020 (last available)
shape_data20 <- st_read(paste0(rootdir,"shapefiles/counties_cz/CommutingZones2020_County_GIS_files-d81d51023719c241/county20.shp"))

# Quickly visualize the shape files - 3,222 counties and 593 CZs
if (1 == 2) {
  # 2010- 625 CZs and 3,143 counties
  length(unique(shape_data10$OUT10))
  length(unique(shape_data10$FIPS))
  ggplot(shape_data10) + 
    geom_sf(fill="#69b3a2", color="white", size=0.001) + 
    theme_void()
  
  # 2020 - 593 CZs and 3,222 counties
  length(unique(shape_data20$CZ20))
  length(unique(shape_data20$GEOID))
  ggplot(shape_data20) + 
    geom_sf(fill="#69b3a2", color="white", size=0.001) + 
    theme_void()
}

setDT(shape_data10)
shape_data10 <- shape_data10[, county := as.numeric(FIPS)]
shape_data10 <- unique(shape_data10[, .(county, OUT10)])
setnames(shape_data10, "OUT10", "cz10")

setDT(shape_data20)
shape_data20 <- shape_data20[, county := as.numeric(GEOID)]
shape_data20 <- unique(shape_data20[, .(county, CZ20)])
setnames(shape_data20, "CZ20", "cz20")

# Merge on
ziptocountytocz <- left_join(ziptocounty, shape_data10, by = "county")
ziptocountytocz <- left_join(ziptocountytocz, shape_data20, by = "county")
# How many counties missing CZ20?
length(unique(ziptocountytocz$county[is.na(ziptocountytocz$cz20)]))
ziptocountytocz <- ziptocountytocz %>% 
  # Replace CZ20 for the missing county in IN. 46113 changed to 46102 in 2013 -> CZ 351
  mutate(cz20=if_else(county=="46113",351,cz20)) %>%  
  # Replace CZ20 with 88 for the Connecticut counties that were updated to county equivalent in 2020
  # The CT counties have been updated to county equivalents end of 2022
  # see https://developer.ap.org/ap-elections-api/docs/CT_FIPS_Codes_forPlanningRegions.htm
  # all are part of CZ 88
  mutate(cz20=if_else(str_detect(county,"^9[0-9][0-9][0-9]")==TRUE,88,cz20)) %>% 
  # 2261 in Alaska was split into 2063 and 2066
  mutate(cz20=if_else(county==2261,17,cz20)) %>% 
  # 2270 in Alaska was changed to 2158
  mutate(cz20=if_else(county==2270,24,cz20)) 

# All have CZ20
notok <- ziptocountytocz[is.na(cz20),]
stopifnot(length(notok$zip) == 0)

# Save out
ziptocountytocz <- ziptocountytocz[,.(zip,county,cz20)]
fwrite(ziptocountytocz,file=paste0(rootdir,"crosswalk_spatial/output/ziptocountytocz.csv"))
