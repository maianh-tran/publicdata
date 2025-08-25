library(dplyr)
library(tidyverse)
library(openxlsx)
library(readxl)
library(data.table)
library(haven)

rm(list=ls())
rootdir <- "~/Dropbox/publicdata/"

# ===================================
# Combine to commuting zone level
# ===================================
# Load county to CZ crosswalk 
county_master0 <- fread(file=paste0(rootdir,"crosswalk_spatial/output/ziptocountytocz.csv"))
county_master0 <- unique(county_master0[,.(county,cz20)])
county_master0 <- county_master0[,county:=as.character(str_sub(paste0("00000",county),start=-5))]
year <- c(2012,2016,2022)
county_master1 <- crossing(county_master0,year)

# Load CT equivalent crosswalk for post 2022
county_ct <- read_excel(paste0(rootdir,"crosswalk_spatial/rawdata/county_updates.xlsx"),sheet="CT")
county_ct <- county_ct %>% 
  mutate(county=as.character(str_sub(paste0("00000",county),start=-5))) %>% 
  select(c("year","county","cz20")) 

# Load VA changes
county_va <- read_excel(paste0(rootdir,"crosswalk_spatial/rawdata/county_updates.xlsx"),sheet="VA")
county_va <- county_va %>% 
  mutate(county=as.character(str_sub(paste0("00000",county),start=-5))) %>% 
  select(c("year","county","cz20")) 

# Load AK changes
county_ak <- read_excel(paste0(rootdir,"crosswalk_spatial/rawdata/county_updates.xlsx"),sheet="AK")
county_ak <- county_ak %>% 
  mutate(county=as.character(str_sub(paste0("00000",county),start=-5))) %>% 
  select(c("year","county","cz20")) 

# Let CT, VA, AK counties be updated 
county_master2 <- county_master1 %>% 
  filter(!(year==2022 & str_detect(county,"^09[0-9][0-9][0-9]"))) %>% 
  filter(!(year %in% c("2016","2022") & county=="46113")) %>% 
  filter(!((year==2022 & county=="02261") | (year %in% c(2016,2022) & county=="02270")))
county_master <- rbind(county_master2,county_ct,county_va,county_ak)  
setDT(county_master)

# Master CZ list
cz_master <- unique(county_master[,.(year,cz20)])

# ===================================
# Aggregate Gazetteer data
# ===================================
load(paste0(rootdir, "local_area_characteristics/output/county_gazetteer.RData"))
county_gazetteer <- county_gazetteer[,.(year,county,aland_all,aland_sqmi_all)]
# Grab commuting zone 
cz_gazetteer0 <- merge(county_master,county_gazetteer,by=c("county","year"),all.x=TRUE)
stopifnot(length(cz_gazetteer0$county[is.na(cz_gazetteer0$aland_all)])==0)
# Collapse to CZ level
cz_gazetteer <- cz_gazetteer0[, lapply(.SD, sum), .SDcols = c("aland_all",
                                                              "aland_sqmi_all"), 
                              by = c("cz20", "year")]

# ===================================
# Aggregate ACS 5 year data
# ===================================
load(paste0(rootdir, "local_area_characteristics/output/county_acs5.RData"))
# Grab commuting zone 
cz_acs5_0 <- merge(county_master,county_acs5,by=c("county","year"),all.x=TRUE)
stopifnot(length(cz_acs5_0$county[is.na(cz_acs5_0$gender1)])==0)
# Aggregate all except median household income
measures <- names(cz_acs5_0)[!names(cz_acs5_0) %in% c("year",
                                                      "cz20",
                                                      "county",
                                                      "NAME",
                                                      "medinc")]

cz_acs5_1 <- cz_acs5_0[, lapply(.SD, sum), .SDcols = measures, by = c("cz20", "year")]
# Median of median household income 
cz_acs5_2 <- cz_acs5_0[, lapply(.SD, median), .SDcols = c("medinc"), by = c("cz20", "year")]
# Combine 
cz_acs5 <- merge(cz_acs5_1,cz_acs5_2,by=c("cz20", "year"),all.x=TRUE)

# ===================================
# Aggregate election results
# ===================================
county_election_results <- read_dta(paste0(rootdir, "local_area_characteristics/output/county_election_results.dta"))
county_election_results <- county_election_results %>%
  mutate(orig_year_election=year) %>%
  mutate(year=if_else(year==2020,2022,year)) %>%  # use 2020 results as proxy for 2022
  select(c("county",contains("year"),contains("votes")))
# Separate the CT results in 2020 
county_election_results_CT <- county_election_results %>% 
  filter(orig_year_election==2020 & str_detect(county,"^09[0-9][0-9][0-9]")) %>% 
  mutate(cz20=88)
# Grab commuting zone 
cz_election_results0 <- merge(county_master,county_election_results,by=c("county","year"),all.x=TRUE)
# Drop the CT equivalent counties in 2022 and replace back with county 
cz_election_results1 <- cz_election_results0[!(str_detect(county,"^09[0-9][0-9][0-9]") & year==2022)]
cz_election_results2 <- rbind(cz_election_results1,county_election_results_CT)
# All should have vote count aside from districts 41 - onwards in alaska
stopifnot(length(cz_election_results2$county[is.na(cz_election_results2$totalvotes) & !str_detect(cz_election_results2$county,"^02[0-9][0-9][0-9]")])==0)
# Collapse to CZ level
cz_election_results <- cz_election_results2[, lapply(.SD, sum,na.rm=FALSE), .SDcols = c("totalvotes",
                                                                            "candidatevotesdem",
                                                                            "candidatevotesrep"), 
                                            by = c("cz20", "year", "orig_year_election")]

# ===================================
# Aggregate UA pop
# ===================================
load(paste0(rootdir, "local_area_characteristics/output/county_ua.RData"))
county_ua <- county_ua %>%
  mutate(orig_year_ua=year) %>%
  mutate(year=if_else(orig_year_ua==2010,2012,2022)) # proxy 2010 for 2012 and 2020 for 2022
# Grab commuting zone 
cz_ua0 <- merge(county_master,county_ua,by=c("county","year"),all.x=TRUE)
stopifnot(length(cz_ua0$county[is.na(cz_ua0$pop_tot) & cz_ua0$orig_year_ua %in% c(2010,2020)])==0)
# Collapse to CZ level
cz_ua <- cz_ua0[, lapply(.SD, sum), .SDcols = c("pop_tot",
                                                "pop_urban"), 
                by = c("cz20", "year", "orig_year_ua")]
# Calculate pct urban
cz_ua <- cz_ua[,poppct_urban:=pop_urban/pop_tot]

# ===================================
# Merge them all
# ===================================
mlist <- list(cz_master,
              cz_gazetteer,
              cz_acs5,
              cz_election_results,
              cz_ua)

cz_combined <- Reduce(function(x, y) merge(x, y, by = c("year","cz20"), all = TRUE), mlist)

# Calculate population density per square miles
cz_combined <- cz_combined[, popdens:=population/aland_sqmi_all]
setcolorder(cz_combined, c("year","cz20"))

save(cz_combined, file = paste0(rootdir, "local_area_characteristics/temp/cz_combined.RData"), compress=TRUE)
  
# EOF #
