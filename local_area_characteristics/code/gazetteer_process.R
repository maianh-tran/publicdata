library(tidycensus)
library(dplyr)
library(tidyverse)
library(openxlsx)
library(data.table)
library(labelled)

rm(list=ls())
rootdir <- "~/Dropbox/publicdata/"

# ===================================================
# GAZETTEER ALL DATA
# ===================================================
setwd(paste0(rootdir,"local_area_characteristics/rawdata/gazetteer"))

# List all the text files
files <- list.files(pattern = ".*_Gaz_counties_national\\.txt$")
# Read and append all files into one data frame, adding a 'year' variable
county_gazetteer_all <- do.call(rbind, lapply(files, function(file) {
  # Extract the year from the filename (assumes the format 'YYYY_Gaz_counties_national.txt')
  year <- sub("_.*", "", file)  # Extract everything before the first underscore
  # Read the file
  df <- read_delim(file, delim = "\t", trim_ws = TRUE)
  # Add the 'year' column
  df$year <- as.integer(year)
  return(df)
}))

setDT(county_gazetteer_all)
var_label(county_gazetteer_all$ALAND) <- "Land area in square meters"
var_label(county_gazetteer_all$AWATER) <- "Water area in square meters"
var_label(county_gazetteer_all$ALAND_SQMI) <- "Land area in square miles"
var_label(county_gazetteer_all$AWATER_SQMI) <- "Water area in square miles"
var_label(county_gazetteer_all$INTPTLAT) <- "County latitude"
var_label(county_gazetteer_all$INTPTLONG) <- "County longitude"

setnames(county_gazetteer_all,c("GEOID","ALAND","AWATER","ALAND_SQMI","AWATER_SQMI"),c("county","aland_all","awater_all","aland_sqmi_all","awater_sqmi_all"))

county_gazetteer <- county_gazetteer_all
save(county_gazetteer, file = paste0(rootdir,"local_area_characteristics/output/county_gazetteer.RData"),compress=TRUE)

# ===================================================
# GAZETTEER URBAN DATA
# ===================================================
files <- list.files(pattern = ".*_Gaz_ua_national\\.txt$")
# Read and append all files into one data frame, adding a 'year' variable
county_gazetteer_ua <- do.call(rbind, lapply(files, function(file) {
  # Extract the year from the filename (assumes the format 'YYYY_Gaz_counties_national.txt')
  year <- sub("_.*", "", file)  # Extract everything before the first underscore
  # Read the file
    df <- read_delim(file, delim = "\t", trim_ws = TRUE)
  # Add the 'year' column
  df$year <- as.integer(year)
  return(df)
}))

setDT(county_gazetteer_ua)
var_label(county_gazetteer_ua$ALAND) <- "Land area in square meters - Urban"
var_label(county_gazetteer_ua$AWATER) <- "Water area in square meters - Urban"
var_label(county_gazetteer_ua$ALAND_SQMI) <- "Land area in square miles - Urban"
var_label(county_gazetteer_ua$AWATER_SQMI) <- "Water area in square miles - Urban"
county_gazetteer_ua <- county_gazetteer_ua[,.(year, GEOID,ALAND,AWATER,ALAND_SQMI,AWATER_SQMI)]

setnames(county_gazetteer_ua,c("GEOID","ALAND","AWATER","ALAND_SQMI","AWATER_SQMI"),c("county","aland_ua","awater_ua","aland_sqmi_ua","awater_sqmi_ua"))
save(county_gazetteer_ua, file = paste0(rootdir,"local_area_characteristics/output/county_gazetteer_urban.RData"),compress=TRUE)

# EOF 
