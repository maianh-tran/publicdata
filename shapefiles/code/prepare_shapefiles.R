library(sf)
library(tigris)
library(maps)
library(ggplot2)
library(dplyr)
library(tidyr)
library(data.table)
library(RColorBrewer)
library(scales)
library(viridis)
library(ggpattern)
library(cartography)
library(purrr)
library(stringr)
library(haven)

rm(list = ls())

# Paths
projectroot <- "~/Dropbox/publicdata/shapefiles/"
raw <- paste0(projectroot, "rawdata/")
output <- paste0(projectroot, "output/")

# Territory state codes
territory <- c("60", "66", "69", "72")

# ========================================
# COUNTY SHAPEFILE
# ========================================
# County and CZ
cw_raw <- st_read(paste0(raw, "county20.shp"))
setDT(cw_raw)

statefip_data <- st_read(paste0(raw, "Census Shapefiles/tl_2018_us_county/tl_2018_us_county.shp"))
setDT(statefip_data)
statefip <- unique(statefip_data[, .(GEOID, STATEFP)])
cw_data <- merge(cw_raw, statefip, by="GEOID", all.x=TRUE)

cw_data <- cw_data[, statecode := case_when(
  GEOID == "02063" ~ "02",
  GEOID == "02066" ~ "25",
  str_detect(GEOID,"091[0-9]0") ~ "09"
)]
cw_data <- cw_data[, statecode := case_when(
  is.na(statecode) ~ STATEFP,
  !is.na(statecode) ~ statecode
)]

# County names
countynames <- fread(paste0(raw, "dataverse_files/countyfips.csv"))
countynames <- countynames[, .(FIPS, state, county)]
countynames$county <- str_to_title(countynames$county)
countynames <- countynames[, cou_name := paste0(county, ", ", state)]
countynames <- countynames[, county := paste0("00000", FIPS)]
countynames <- countynames[, GEOID := substr(county, nchar(county)-4, nchar(county))]
setnames(countynames, "cou_name", "cou_st_name")
countynames <- countynames[, st_name := str_sub(cou_st_name, start=-2)]
countynames <- countynames[, cou_name := sub("^(.*?),.*", "\\1", cou_st_name)]

cw_data <- left_join(cw_data, countynames, by="GEOID")

# Exclude AL, AK, HI
cw_data <- cw_data[, restricted := case_when(statecode == "01" ~ 1, statecode != "01" ~ 0)]
cw_data <- cw_data[, noncont := case_when(statecode %in% c("02","15","72") ~ 1, TRUE ~ 0)]

# Visualization
if (1==2) {
  cw_data <- st_as_sf(cw_data)
  ggplot(data=cw_data) +
    geom_sf(fill="#69b3a2", color="white") +
    theme_void()
}

st_write(cw_data, paste0(output, "county20shapefile.shp"), append=FALSE)

# ========================================
# CZ SHAPEFILE
# ========================================
# Convert county to CZ
commuting_zone0 <- cw_data %>% group_by(CZ20, statecode) %>% summarise(geometry=st_union(geometry))
commuting_zone0 <- commuting_zone0 %>% group_by(CZ20) %>% mutate(ct_state=length(unique(statecode)))

commuting_zone0 <- commuting_zone0 %>%
  mutate(restricted=if_else(statecode=="01",1,0),
         noncont=if_else(statecode %in% c("02", "15", "72"),1,0))

commuting_zone0 <- commuting_zone0 %>%
  group_by(CZ20) %>%
  mutate(restricted=max(restricted),
         noncont=max(noncont))

if (1==2) {
  commuting_zone2 <- commuting_zone0
  commuting_zone2 <- st_as_sf(commuting_zone2)
  commuting_zone2 <- commuting_zone2 %>% filter(noncont==0)
  ggplot() +
    geom_sf(fill="#69b3a2", color="white") +
    theme_void()
}

# County and state names
commuting_zone_names <- cw_data %>%
  group_by(CZ20, statecode) %>%
  mutate(cou_st_name = if_else(is.na(cou_st_name), "", cou_st_name)) %>%
  mutate(st_name = if_else(is.na(st_name), "", st_name)) %>%
  mutate(cou_name = if_else(is.na(cou_name), "", cou_name)) %>%
  mutate(included_cou_st0 = paste(cou_st_name, collapse="; ")) %>%
  mutate(included_cou0 = paste(cou_name, collapse="; ")) %>%
  select(c("CZ20", "statecode", "included_cou_st0", "included_cou0", "st_name", "GEOID")) %>%
  distinct()

commuting_zone_names$included_cou_st0[commuting_zone_names$CZ20==88] <- "All Counties in CT"
commuting_zone_names$st_name[commuting_zone_names$CZ20==88] <- "CT"

commuting_zone_names <- commuting_zone_names %>%
  group_by(CZ20) %>%
  mutate(included_st = paste(st_name, collapse="; ")) %>%
  mutate(included_cou = paste(included_cou0, collapse="; ")) %>%
  mutate(included_cou_st = paste(included_cou_st0, collapse="; ")) %>%
  ungroup() %>%
  select(c("CZ20", "included_cou_st", "included_cou", "included_st")) %>%
  distinct()

# Census top 2 population counties
load(file = paste0("~/Dropbox/publicdata/local_area_characteristics/output/county_acs5.RData"))
county_acs5 <- county_acs5[year==2012 | year==2022]
setnames(county_acs5,"county","GEOID")
county_pop <- left_join(select(cw_data,CZ20,GEOID,cou_st_name), select(county_acs5,GEOID,population,year), by="GEOID")

top_pop <- county_pop %>%
  group_by(CZ20, year) %>%
  top_n(3, population) %>%
  group_by(CZ20, year) %>%
  arrange(CZ20, year, population) %>%
  mutate(top_pop = paste(cou_st_name, collapse="; ")) %>%
  ungroup() %>%
  select(c("CZ20", "year", "top_pop")) %>%
  distinct()

top_pop <- spread(top_pop, key="year", value="top_pop")
setnames(top_pop, c("2012", "2022"), c("top_cou_2012", "top_cou_2022"))

# Save out shapefile
commuting_zone <- left_join(commuting_zone0, commuting_zone_names, by="CZ20")
commuting_zone <- left_join(commuting_zone, top_pop, by="CZ20")
setDT(commuting_zone)

st_write(commuting_zone, paste0(output, "cz20shapefile.shp"), append=FALSE)
# fwrite(commuting_zone, paste0(output, "cz20shapefile.csv"))

# ========================================
# HRR SHAPEFILE
# ========================================
hrr_raw <- st_read(paste0(raw, "HRR Shapefiles/HRR_Bdry__AK_HI_unmodified/hrr-shapefile/Hrr98Bdry_AK_HI_unmodified.shp"))
setDT(hrr_raw)
hrr_data <- hrr_raw[, restricted := if_else(grepl("^AL", hrrcity), 1, 0)]
hrr_data <- hrr_data[, noncont := if_else(grepl("^(AK|HI)", hrrcity), 1, 0)]

st_write(hrr_data, paste0(output, "hrrshapefile.shp"), append=FALSE)
