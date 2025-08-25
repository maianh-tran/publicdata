library(dplyr)
library(labelled)
library(tidyverse)
library(openxlsx)
library(data.table)
library(readxl)

rm(list=ls())
rootdir <- "~/Dropbox/publicdata/"

# ================================
# LOAD COUNTY CODEBOOK DATA
# ================================
# 2010
ua10 <- read_excel(paste0(rootdir, "local_area_characteristics/rawdata/urban/PctUrbanRural_County.xls"))
setDT(ua10)
ua10 <- ua10[, year:=2010
             ][, GEOID:=paste0(STATE, COUNTY)]
ua10 <- ua10[,.(GEOID, year,
                POP_COU,
                POP_URBAN,
                POPPCT_URBAN)]

# 2020
ua20 <- read_excel(paste0(rootdir, "local_area_characteristics/rawdata/urban/2020_UA_COUNTY.xlsx"))
setDT(ua20)
ua20 <- ua20[, year:=2020
             ][, GEOID:=paste0(STATE, COUNTY)]
ua20 <- ua20[,.(GEOID, year,
                POP_COU,
                POP_URB,
                POPPCT_URB)]

setnames(ua20, c("POP_URB","POPPCT_URB"), c("POP_URBAN","POPPCT_URBAN"))

county_ua <- rbind(ua10, ua20)

setnames(county_ua, c("GEOID","POP_COU","POP_URBAN","POPPCT_URBAN"), c("county","pop_tot","pop_urban","poppct_urban"))
save(county_ua, file = paste0(rootdir, "local_area_characteristics/output/county_ua.RData"), compress=TRUE)

# EOF #
