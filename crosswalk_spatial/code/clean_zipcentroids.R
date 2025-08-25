library(data.table)
library(readxl)
library(dplyr)
library(stringr)
library(zoo)
library(haven)
library(hereR)
library(here)
library(tidyverse)
library(httr)
library(readr)
library(sf)
library(tidygeocoder)
library(tictoc)
library(jsonlite)
library(glue)
library(janitor)
library(progressr)
library(knitr)
library(kableExtra)

rm(list=ls())
rootdir <- "~/Dropbox/publicdata/"

# ===================================
# Census tract to zip mapping from GEOCORR Engine 
# ===================================
tract_to_zip2000 <-
  read.csv(paste0(rootdir,"crosswalk_spatial/rawdata/zip_centroid/geocorr2000_30DEC0902922.csv"),skip=1) %>%
  as_tibble() %>%
  janitor::clean_names() %>% 
  mutate(year=2000)

setnames(tract_to_zip2000,
         c("wtd_centroid_w_longitude_degrees",
          "wtd_centroid_latitude_degrees",
          "total_pop_2000_census",
          "tract_to_zcta5_allocation_factor"),
         c("wtd_centroid_long",
           "wtd_centroid_lat",
           "total_pop",
           "allocation_factor"))

tract_to_zip2014 <-
  read.csv(paste0(rootdir,"crosswalk_spatial/rawdata/zip_centroid/geocorr2014_2436504269.csv"),skip=1) %>%
  as_tibble() %>%
  janitor::clean_names() %>% 
  mutate(year=2014)

setnames(tract_to_zip2014,
         c("wtd_centroid_w_longitude_degrees",
           "wtd_centroid_latitude_degrees",
           "total_population_2010",
           "tract_to_zcta5_allocation_factor"),
         c("wtd_centroid_long",
           "wtd_centroid_lat",
           "total_pop",
           "allocation_factor"))

tract_to_zip2022 <-
  read.csv(paste0(rootdir,"crosswalk_spatial/rawdata/zip_centroid/geocorr2022_2436500573.csv"),skip=1) %>%
  as_tibble() %>%
  janitor::clean_names() %>% 
  mutate(year=2022)

setnames(tract_to_zip2022,
         c("weighted_centroid_west_longitude",
           "weighted_centroid_latitude",
           "total_population_2020_census",
           "tract_to_zcta_allocation_factor"),
         c("wtd_centroid_long",
           "wtd_centroid_lat",
           "total_pop",
           "allocation_factor"))

# ===================================
# Calculate population-weighted zip code centroids
# ===================================
createfile <- function(input) {
    output <- input %>% 
    group_by(zip_census_tabulation_area,year) %>%
    mutate(population_weight = allocation_factor * total_pop) %>%
    summarise_at(
      vars(
        wtd_centroid_lat,
        wtd_centroid_long
      ),
      ~ weighted.mean(., w = .data$population_weight)
    ) %>%
    select(zip = zip_census_tabulation_area,
           y = wtd_centroid_lat,
           x = wtd_centroid_long,
           year = year) %>%
    st_as_sf(coords = c("x", "y"), crs = 4326) %>%
    bind_cols(st_coordinates(.) %>% as_tibble() %>% set_names(c("x", "y"))) %>%
    mutate(zip = str_pad(
      zip,
      width = 5,
      side = "left",
      pad = "0"
    ))
  
}

sf_zip_centroids2000 <- createfile(tract_to_zip2000)
sf_zip_centroids2014 <- createfile(tract_to_zip2014)
sf_zip_centroids2022 <- createfile(tract_to_zip2022)

# Append the three
sf_zip_centroids <- rbind(sf_zip_centroids2000,sf_zip_centroids2014,sf_zip_centroids2022)
# Transpose wide
setDT(sf_zip_centroids)
sf_zip_centroids <- sf_zip_centroids %>% pivot_wider(names_from = year, values_from = c("geometry", "x", "y"))

# ===================================
# Zip crosswalks
# ===================================
crosswalk <- fread(paste0(rootdir,"crosswalk_spatial/output/ziptocounty_2022.csv"))
crosswalk[,zip:=str_sub(paste0("00000",zip),start=-5)]

# merge centroids
centroids <- left_join(crosswalk,sf_zip_centroids,by="zip")
# do all zips have centroids?
length(unique(centroids$zip[!is.na(centroids$x_2022)]))
length(unique(centroids$zip[!is.na(centroids$x_2014)]))
length(unique(centroids$zip[!is.na(centroids$x_2000)]))

length(unique(centroids$zip[!is.na(centroids$x_2022) | !is.na(centroids$x_2014) | !is.na(centroids$x_2000)]))
length(unique(centroids$zip))

# Map of TN
data(fips_codes,package="tidycensus")
county_xw <-
  fips_codes %>%
  as_tibble() %>%
  mutate(county = gsub(" County$","",county)) %>%
  mutate(fips = paste0(state_code, county_code)) %>%
  select(county_name = county,state, state_code, county_code,fips)
state_xw <-
  county_xw %>%
  select(state_name = state,STATEFP = state_code) %>%
  unique()
counties <-
  tigris::counties(year = 2017) %>%
  inner_join(state_xw,"STATEFP") %>%
  filter(state_name == "TN")

p0 <-
  counties %>%
  ggplot() +
  geom_sf(fill=NA) +
  # use theme_map()
  theme_void()
p0








