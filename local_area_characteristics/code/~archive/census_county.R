library(tidycensus)
library(dplyr)
library(tidyverse)
library(openxlsx)
library(data.table)
library(readxl)

rm(list=ls())

# Load Gazetteer data
load("~/Dropbox/pricegrowth/databuild/census/output/county_gazetteer.RData")
county_gazetteer <- county_gazetteer[,.(year,GEOID,aland_all,aland_sqmi_all)]

# Load ACS 5 year data
load("~/Dropbox/pricegrowth/databuild/census/output/county_acs5.RData")

# Load urban rural data 2010 
county_ua10 <- read_excel("~/Dropbox/pricegrowth/databuild/census/rawdata/PctUrbanRural_County.xls")

# Load urban rural data 2020
county_ua20 <- read_excel("~/Dropbox/pricegrowth/databuild/census/rawdata/2020_UA_COUNTY.xlsx")

# Merge the two
county_census <- full_join(county_acs5,county_gazetteer,by=c("year","GEOID"))

# Calculate population density per square miles
county_census <- county_census[,popdens:=population/aland_sqmi_all]
save(county_census, file = "~/Dropbox/pricegrowth/databuild/census/output/county_census.RData",compress=TRUE)

# EOF #