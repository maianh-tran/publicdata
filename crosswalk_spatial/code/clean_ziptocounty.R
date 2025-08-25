library(data.table)
library(readxl)
library(readxl)
library(dplyr)
library(stringr)
library(zoo)

rm(list=ls())
rootdir <- "~/Dropbox/publicdata/"

# ===================================
# Clean zip to county crosswalks
# ===================================
# Function to read each Excel file
read_file <- function(file) {
  # extract quarter
  q <- str_extract_all(file, "([0-9][0-9][0-9][0-9][0-9][0-9]).xlsx")[[1]]
  q <- str_replace(q, "\\.xlsx$", "")
  
  ds <- read_excel(file)
  ds <- ds %>%
    mutate(quarter=q)
  names(ds) <- tolower(names(ds))
  return(ds)
}

# List all files in the directory with the pattern "zip_county_****.xlsx"
file_list <- list.files(path = paste0(rootdir,"crosswalk_spatial/rawdata/zip_crosswalk"), pattern = "zip_county_\\d{6}\\.xlsx", full.names = TRUE)

# Read and combine all files
combined_data0 <- bind_rows(lapply(file_list, read_file))

# Clean
combined_data0 <- combined_data0 %>%
  select(-"...7") %>%
  filter(!(is.na(zip)) & !(is.na(county))) %>% 
  mutate(year=substr(quarter,3,6)) %>%
  mutate(quarter=as.numeric(substr(quarter,1,2))/3) %>% 
  mutate(county=as.character(str_sub(paste0("00000",county),start=-5)))

combined_data <- combined_data0 %>% 
  mutate(state=as.numeric(str_extract(county,"^[0-9][0-9]"))) %>% 
  filter(state<=56)  # Do not care if U.S. territories
setDT(combined_data)

# ===================================
# Allocate in case of 1:m zip to county
# ===================================
# any duplicates within a zip/quarter/year?
combined_data <- combined_data[, rows:=.N, by=c("zip","quarter","year")]
head(combined_data[rows>1],100)

# first, assign zip to the county with highest res_ratio
dedup0 <- combined_data[, `:=`(maxres_ratio=max(res_ratio),
                               maxtot_ratio=max(tot_ratio)),
                        by=c("zip","quarter","year")]
dedup0 <- dedup0[rows==1 | (res_ratio==maxres_ratio & rows>1)]

# still dups?
dedup0[, rows:=.N, by=c("zip","quarter","year")]
head(dedup0[rows>1],100)

# then highest tot_ratio
dedup1 <- dedup0[, rows:=.N, by=c("zip","quarter","year")]
dedup1 <- dedup1[rows==1 | (maxtot_ratio==tot_ratio & rows>1)]

# still dups?
dedup1[, rows:=.N, by=c("zip","quarter","year")]
head(dedup1[rows>1],100)

# then assign to county that appear in most number of quarters within the zip throughout the year
dedup2 <- dedup1[, rows:=.N, by=c("zip","quarter","year")]
dedup2 <- dedup2[, n:=.N, by=c("county","zip","year")]
dedup2[, max_n:=max(n), by=c("zip","year")]
dedup2 <- dedup2[rows==1 | (n==max_n & rows>1)]

# still dups?
dedup2[, rows:=.N, by=c("zip","quarter","year")]
head(dedup2[rows>1],100)

# then backward quarter without dup. For example, if Q22013 has dups and Q32013 does not,
# fill backward Q32013 for Q22013.
dedup3 <- dedup2[, rows:=.N, by=c("zip","quarter","year")]
dedup3 <- dedup3[, countyclean:=ifelse(rows==1, county, NA)]

setorder(dedup3, zip, -year, -quarter)
dedup3[, countyclean:=na.locf(countyclean, na.rm=FALSE), by=zip]

# some code to test
test <- dedup3[, .(zip, quarter, year, zip, res_ratio, tot_ratio, countyclean, county, rows)]
test[zip==22908]
rm(test)

# no more dups!
dedup3 <- dedup3 %>%
  select(-county) %>%
  distinct() %>%
  rename(county=countyclean)

anyDuplicated(dedup3, by=c("zip","quarter","year"))
# good to go
final0 <- dedup3 %>%
  select(-c("n","max_n","rows",starts_with("max")))

# ===================================
# Save out a quarter/year version
# ===================================
quarter <- final0[,.(year,quarter,zip,county)]
setorder(quarter,quarter,year,zip,county)
fwrite(quarter, file=paste0(rootdir,"crosswalk_spatial/output/ziptocounty_quarter.csv"))

# ===================================
# Save out a month/year version
# ===================================
month <- quarter[rep(seq_len(.N), each = 3)]
month <- month[, num := rep(1:3, times = .N/3)
               ][, month := num * quarter
                 ][,.(year,month,zip,county)]  
fwrite(month, file=paste0(rootdir,"crosswalk_spatial/output/ziptocounty_month.csv"))

# ===================================
# Save out a unique version - last not missing county that a zip is matched to
# ===================================
# get zip to county crosswalk in last quarter of 2022 
# if missing, replace with whatever is last available 

# for each zip/year, get the last quarter
last0 <- quarter[!(is.na(zip)) & !(is.na(county)),]
last0 <- last0[,last_quarter:=max(quarter),by=c("zip","year")]
last0 <- last0[quarter==last_quarter,]

# for each zip, get the last year 
last0 <- last0[,last_year:=max(year),by="zip"]
last <- last0[year==last_year,][,.(year,quarter,zip,county)]

# the majority of zips appear in 2022
zip_tot <- length(unique(last$zip))
zip_2022 <- length(unique(last$zip[last$year==2022]))
stopifnot(zip_2022/zip_tot > 0.99)

last <- last[,.(zip,county)]
fwrite(last, file=paste0(rootdir,"crosswalk_spatial/output/ziptocounty_2022.csv"))
