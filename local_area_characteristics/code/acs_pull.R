library(tidycensus)
library(dplyr)
library(tidyverse)
library(openxlsx)
library(data.table)

rm(list=ls())
rootdir <- "~/Dropbox/publicdata/"
census_api_key("1cc69f2fa85159a956494926c3ed9c264eefd099", install=TRUE, overwrite=TRUE)

# ===================================================
# ACS DATA
# ===================================================
# Useful resource for table codes: https://censusreporter.org/topics/table-codes/
# All available variables
acs1 <- load_variables(2021, "acs1", cache = TRUE)
acs5 <- load_variables(2021, "acs5", cache = TRUE)

# List of covariates we want 
# sex by age by race (^B01001)
  # White alone (e.g., B01001A_007 -- B01001A_013 Male 18 and 19, White; B01001A_022 -- B01001A_028  Female 18 and 19, White)
  # Black or African American alone
  # American Indian and Alaska Native alone
  # Asian alone
  # Native Hawaiian and Other Pacific Islander alone
  # Some Other Race alone
  # Two or More Races
  # Hispanic or Latino (B01001I_007 -- B01001I_013 Male 18-64, Hispanic or Latino; B01001I_022 -- B01001I_028 Female 18-64, Hispanic or Latino)
# sex by age by educational attainment (^B15001) (18-24; 25-34; 35-44; 45-64)
  # less than 9th grade
  # 9th to 12th grade, no diploma
  # High school graduate (includes equivalency)
  # Some college, no degree
  # Associate's degree
  # Bachelor's degree
  # Graduate or professional degree
# with health insurance coverage by sex by age (^B27001)
  # with health insurance coverage
  # without health insurance coverage
# private health insurance by sex by age (^C27002 is the simplified version with 19-64 but could not find. ^B27002 breaks down into smaller age group)
  # with private health insurance
  # without private health insurance
# employment (^C23002A is the simplified version with 16-64. just so we have it, ^B23002A breaks down by age)
# median household income (we will use ^B19013. ^B19049 breaks down by age of householder, but lowest age is 25)
# share under poverty (^B17001)
# civilian employed population 16 years and older (^C24030)
# population, as numerator to later calculate population density (^B01003)

acs5 <- acs5 %>% 
  mutate(forfilter1=trimws(substr(name,1,6))) %>% 
  mutate(forfilter2=trimws(substr(name,1,7)))

acs5_filtered <- acs5 %>% 
  filter(forfilter1 %in% c("B01001","B15001","B27002","B19013","B17001","B27001","B01003","C24030") | forfilter2 %in% c("C23002A")) %>%
  rename("variable"="name") %>%
  select(-c("geography",starts_with("forfilter")))
covaracs5 <- unique(acs5_filtered$variable)

acs1 <- acs1 %>% 
  mutate(forfilter1=trimws(substr(name,1,6))) %>% 
  mutate(forfilter2=trimws(substr(name,1,7)))
acs1_filtered <- acs1 %>% 
  filter(forfilter1 %in% c("B01001","B15001","B27002","B19013","B17001","B01003","C24030") | forfilter2 %in% c("C27001A","C23002A")) %>%
  rename("variable"="name") %>% 
  select(-starts_with("forfilter"))
covaracs1 <- unique(acs1_filtered$variable)

# ===================================================
# PULL COUNTY LEVEL 5-YEAR 
# ===================================================
# Set desired years
years <- c(2012,2016,2022)
rawdataacs5 <- map_dfr(
    years,
  ~ get_acs(
    geography = "county",
    variables = covaracs5,
    year = .x,
    survey = "acs5",
    geometry = FALSE
  ),
  .id = "year" 
) %>% 
  mutate(year=years[as.numeric(year)]) %>% 
  print()

dataacs5 <- merge(rawdataacs5,acs5_filtered,by="variable",all.x=TRUE)
setDT(dataacs5)

# Save out to raw 
save(dataacs5, file = paste0(rootdir,"local_area_characteristics/rawdata/acs/county_acs5.RData"),compress=TRUE)

# EOF #