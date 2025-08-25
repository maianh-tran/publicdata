library(dplyr)
library(tidyverse)
library(openxlsx)
library(readxl)
library(data.table)
library(haven)

rm(list=ls())
rootdir <- "~/Dropbox/publicdata/"

# ===================================
# Combine county
# ===================================
# Load zip to county to CZ crosswalk 
county_master0 <- fread(file=paste0(rootdir,"crosswalk_spatial/output/ziptocountytocz.csv"))
county_master0 <- unique(county_master0[,.(county,cz20)])
county_master0 <- county_master0[,county:=as.character(str_sub(paste0("00000",county),start=-5))]
year <- c(2012,2016,2022)
county_master <- crossing(county_master0,year)

# Load Gazetteer data
load(paste0(rootdir, "local_area_characteristics/output/county_gazetteer.RData"))
county_gazetteer <- county_gazetteer[,.(year,county,aland_all,aland_sqmi_all)]

# Load ACS 5 year data
load(paste0(rootdir, "local_area_characteristics/output/county_acs5.RData"))

# Load election results
county_election_results <- read_dta(paste0(rootdir, "local_area_characteristics/output/county_election_results.dta"))
county_election_results <- county_election_results %>%
  mutate(orig_year=year) %>%
  mutate(year=if_else(year==2020,2022,year)) %>%  # use 2020 results as proxy for 2022
  select(c("county","year",contains("vote")))

# Load UA pop
load(paste0(rootdir, "local_area_characteristics/output/county_ua.RData"))
county_ua <- county_ua %>%
  mutate(orig_year=year) %>%
  mutate(year=if_else(orig_year==2010,2012,2022)) # proxy 2010 for 2012 and 2020 for 2022

# Merge the four
county_census0 <- left_join(county_master, county_acs5, by=c("year","county"))
county_census1 <- left_join(county_census0, county_gazetteer, by=c("year","county"))
county_census2 <- left_join(county_census1, county_ua, by=c("year","county"))
county_census <- left_join(county_census2, county_election_results, by=c("year","county"))
county_census$state <- str_extract(county_census$NAME, "\\b[^,]+$")

# Nowhere is missing ACS5
stopifnot(length(county_census$county[is.na(county_census$gender1)])==0)

# Nowhere is missing election results
stopifnot(length(county_census$county[is.na(county_census$voted_dem)])==0)

# Nowhere is missing UA percentage
stopifnot(length(county_census$county[is.na(county_census$pop_tot) & county_census$year!=2016])==0)

# Calculate population density per square miles
county_census <- county_census[, popdens:=population/aland_sqmi_all]
setcolorder(county_census, c("year","county","NAME","state"))

save(county_census, file = paste0(rootdir, "local_area_characteristics/output/county_combined.RData"), compress=TRUE)

# ===================================
# Combine CZs
# ===================================
# Keep variables to aggregate to CZs 
cz_census0 <- county_census %>% 
  select(-c(contains("vote"),"popdens"))

# Aggregate all except median household income
measures <- names(cz_census0)[!names(cz_census0) %in% c("year",
                                          "orig_year",
                                          "cz20",
                                          "county",
                                          "NAME",
                                          "state",
                                          "medinc")]

cz_census1 <- cz_census0[, lapply(.SD, sum), .SDcols = measures, by = c("cz20", "year")]

# Load CZ level election shares
cz_election_results <- read_dta(paste0(rootdir, "local_area_characteristics/output/cz_election_results.dta"))
cz_election_results <- cz_election_results %>%
  mutate(orig_year=year) %>%
  mutate(year=if_else(year==2020,2022,year)) %>%  # use 2020 results as proxy for 2022
  select(c("cz20","year",contains("voted")))

cz_census2 <- left_join(cz_census1,cz_election_results,by=c("cz20","year"))

# Share of population living in urban area
cz_census2[, poppct_urban := pop_urban / pop_tot]

cz_census0[cz == 88, .(cz, year, poppct_urban)]
cz_census0$poppct_urban[cz_census0$cz == 88 & cz_census0$year == 2022] <- 0.88  # impute 2020 CT
cz_census0[is.na(poppct_urban) & year != 2016, .(cz, year)]

# Mean of median household income w

  
# EOF #
