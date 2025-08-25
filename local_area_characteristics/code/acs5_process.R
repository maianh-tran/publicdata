library(tidycensus)
library(dplyr)
library(tidyverse)
library(openxlsx)
library(data.table)
library(labelled)
library(gtools)
library(Hmisc)
library(haven)

rm(list=ls())
rootdir <- "~/Dropbox/publicdata/"
census_api_key("1cc69f2fa85159a956494926c3ed9c264eefd099", install=TRUE, overwrite=TRUE)

# Useful resource for table codes: https://censusreporter.org/topics/table-codes/
# Note: as of 2020, there are 3,221 counties (https://www.esri.com/arcgis-blog/products/arcgis-living-atlas/mapping/acs-2016-2020-updated-boundaries/#:~:text=In%202020%2C%20one%20Census%20Area,there%20are%20now%203%2C221%20counties.)
# Make sure aggregate counts are consistent across variables 

# All available variables
acs1 <- load_variables(2021, "acs1", cache = TRUE)
acs5 <- load_variables(2021, "acs5", cache = TRUE)

# ===================================================
# PROCESS COUNTY LEVEL 5-YEAR 
# ===================================================
load(paste0(rootdir,"local_area_characteristics/rawdata/acs/county_acs5.RData"))

# Gender and Age
acs5_genderage_raw <- dataacs5[grepl("^B01001",variable) & !grepl("^B01001[A-Z]",variable),
                        ][,label2:=gsub("Estimate!!Total:","",label)
                          ][grepl(".*!!.*!!",label2),]

acs5_genderage <- acs5_genderage_raw[, c("null","gender", "age") := tstrsplit(label2, "!!")
                           ][,null:=NULL
                             ][,`:=` (gender=tolower(trimws(gsub(":","",gender))),
                                      age=tolower(trimws(gsub(":","",age))))]

agevector <- c("18 and 19 years",
               "20 years",
               "21 years",
               "22 to 24 years",
               "25 to 29 years",
               "30 to 34 years",
               "35 to 39 years",
               "40 to 44 years",
               "45 to 49 years",
               "50 to 54 years",
               "55 to 59 years",
               "60 and 61 years",
               "62 to 64 years")

# restrict to 18-64 population
acs5_genderage <- acs5_genderage[age %in% agevector,] 

# group into more aggregate age groups
acs5_genderage <- acs5_genderage %>% 
  mutate(age_orig=age) %>% 
  mutate(age = case_when (
    age_orig %in% c("18 and 19 years","20 years","21 years","22 to 24 years") ~ "18 to 24 years",
    age_orig %in% c("25 to 29 years","30 to 34 years") ~ "25 to 34 years",
    age_orig %in% c("35 to 39 years","40 to 44 years") ~ "35 to 44 years",
    age_orig %in% c("45 to 49 years","50 to 54 years") ~ "45 to 54 years",
    age_orig %in% c("55 to 59 years","60 and 61 years", "62 to 64 years") ~ "55 to 64 years"
    ))

# Sex
acs5_gender <- unique(acs5_genderage[,tot:=sum(estimate,na.rm=TRUE),by=c("year","GEOID","gender")
                                     ][,c("year","GEOID","tot","gender")])
# Transpose wide 
gendervector <- c("male","female")
codevector <- c(1,2)
acs5_gender <- acs5_gender %>%
  mutate(gender = codevector[match(gender, gendervector)]) # encode
acs5_gender <- acs5_gender %>%
  pivot_wider(names_from = gender, 
              values_from = tot,
              names_prefix = "gender")
acs5_gender <- acs5_gender %>% 
  set_variable_labels(
    gender1 = "Male",
    gender2 = "Female"
  )

# Age
acs5_age <- unique(acs5_genderage[,tot:=sum(estimate,na.rm=TRUE),by=c("year","GEOID","age")
                               ][,c("year","GEOID","tot","age")])
# Transpose wide 
agevector <- c("18 to 24 years",
               "25 to 34 years",
               "35 to 44 years",
               "45 to 54 years", 
               "55 to 64 years")
acs5_age$age <- as.integer(factor(acs5_age$age,levels=agevector)) # encode for transposing
acs5_age <- acs5_age %>% # transpose wide
  pivot_wider(names_from = age, 
              values_from = tot,
              names_prefix = "age")
agevars <- mixedsort(names(acs5_age)[grep("^age",names(acs5_age))]) # labeling the variables
for (i in seq_along(agevars)) {
  label(acs5_age[[agevars[i]]]) <- agevector[i]
}
# acs5_age$age_sum <- rowSums(acs5_age[, agevars], na.rm = TRUE)

# Race
acs5_race_raw <- dataacs5[grepl("^B01001[A-Z]",variable),
                          ][,label2:=gsub("Estimate!!Total:","",label)
                            ][grepl(".*!!.*!!",label2),]
acs5_race <- acs5_race_raw[, c("null","gender", "age") := tstrsplit(label2, "!!")
                           ][,null:=NULL
                             ][,`:=` (gender=tolower(trimws(gsub(":","",gender))),
                                  age=tolower(trimws(gsub(":","",age))))]
acs5_race <- acs5_race[,race:=tolower(gsub(".*\\((.*)\\).*", "\\1", concept))]
agevector <- c("18 and 19 years",
               "20 to 24 years",
               "25 to 29 years",
               "30 to 34 years",
               "35 to 44 years",
               "45 to 54 years",
               "55 to 64 years")
racevector <- c("white alone",
                "black or african american alone",
                "american indian and alaska native alone",
                "asian alone",
                "native hawaiian and other pacific islander alone",
                "some other race alone", 
                "two or more races") #  do not include "white alone (not hispanic or latino" and "hispanic or latino", else will be double counting
acs5_race <- unique(acs5_race[race %in% racevector & age %in% agevector,
                              ][,tot:=sum(estimate,na.rm=TRUE),by=c("year","GEOID","race")
                                ][,c("year","GEOID","tot","race")])
# Transpose wide 
acs5_race$race <- as.integer(factor(acs5_race$race,levels=racevector)) # encode for transposing
acs5_race <- acs5_race %>% # transpose wide
  pivot_wider(names_from = race, 
              values_from = tot,
              names_prefix = "race")
racevars <- mixedsort(names(acs5_race)[grep("^race",names(acs5_race))]) # labeling the variables
for (i in seq_along(racevars)) {
  label(acs5_race[[racevars[i]]]) <- racevector[i]
}
# acs5_race$race_sum <- rowSums(acs5_race[, racevars], na.rm = TRUE)

# Education level (^B15001)
acs5_educ <- dataacs5[grepl("^B15001",variable),
                      ][,label2:=gsub("Estimate!!Total:","",label)
                        ][grepl(".*!!.*!!.*!!",label2),]

acs5_educ <- acs5_educ[, c("null","gender","age","education") := tstrsplit(label2, "!!")
                       ][,null:=NULL
                         ][,`:=` (gender=tolower(trimws(gsub(":","",gender))),
                                  age=tolower(trimws(gsub(":","",age))),
                                  education=tolower(trimws(gsub(":","",education))))]
agevector <- c("18 to 24 years",
               "25 to 34 years",
               "35 to 44 years",
               "45 to 64 years")
acs5_educ <- unique(acs5_educ[age %in% agevector,]
                    [,tot:=sum(estimate,na.rm=TRUE),by=c("year","GEOID","education")
                      ][,c("year","GEOID","tot","education")])
# Transpose wide 
educvector <- c("less than 9th grade",
                "9th to 12th grade, no diploma",
                "high school graduate (includes equivalency)",
                "some college, no degree",
                "associate's degree",
                "bachelor's degree",                          
                "graduate or professional degree")
acs5_educ$education <- as.integer(factor(acs5_educ$education,levels=educvector)) # encode for transposing
acs5_educ <- acs5_educ %>% # transpose wide
  pivot_wider(names_from = education, 
              values_from = tot,
              names_prefix = "educ")
educvars <- mixedsort(names(acs5_educ)[grep("^educ",names(acs5_educ))]) # labeling the variables
for (i in seq_along(educvars)) {
  label(acs5_educ[[educvars[i]]]) <- educvector[i]
}
# acs5_educ$educ_sum <- rowSums(acs5_educ[, educvars], na.rm = TRUE)

# Percent insured total (^B27001). Note, 18 yo not included bc of data limitation
acs5_anyins_raw <- dataacs5[grepl("^B27001",variable),
                        ][,label2:=gsub("Estimate!!Total:","",label)
                          ][grepl(".*!!.*!!.*!!",label2),]

acs5_anyins <- acs5_anyins_raw[, c("null","gender","age","anyins") := tstrsplit(label2, "!!")
                       ][,null:=NULL
                         ][,`:=` (gender=tolower(trimws(gsub(":","",gender))),
                                  age=tolower(trimws(gsub(":","",age))),
                                  anyins=tolower(trimws(gsub(":","",anyins))))]
agevector <- c("19 to 25 years",
               "26 to 34 years",
               "35 to 44 years",
               "45 to 54 years",
               "55 to 64 years")
acs5_anyins <- unique(acs5_anyins[age %in% agevector,
                                  ][,tot:=sum(estimate,na.rm=TRUE),by=c("year","GEOID","anyins")
                                    ][,c("year","GEOID","tot","anyins")])
# Transpose wide
anyinsvector <- c("with health insurance coverage",
                  "no health insurance coverage")
codevector <- c(1,0)
acs5_anyins <- acs5_anyins %>%
  mutate(anyins = codevector[match(anyins, anyinsvector)]) # encode
acs5_anyins <- acs5_anyins %>% # transpose wide
  pivot_wider(names_from = anyins, 
              values_from = tot,
              names_prefix = "anyins")
anyinsvars <- mixedsort(names(acs5_anyins)[grep("^anyins",names(acs5_anyins))]) # labeling the variables
anyinsvars <- rev(mixedsort(anyinsvars)) # reverse vector order 
for (i in seq_along(anyinsvars)) {
  label(acs5_anyins[[anyinsvars[i]]]) <- anyinsvector[i]
}
# acs5_anyins$anyins_sum <- rowSums(acs5_anyins[, anyinsvars], na.rm = TRUE)

# Percent on private insurance (^B27002)
acs5_privateins_raw <- dataacs5[grepl("^B27002",variable),
                            ][,label2:=gsub("Estimate!!Total:","",label)
                              ][grepl(".*!!.*!!.*!!",label2),]

acs5_privateins <- acs5_privateins_raw[, c("null","gender","age","privateins") := tstrsplit(label2, "!!")
                                   ][,null:=NULL
                                     ][,`:=` (gender=tolower(trimws(gsub(":","",gender))),
                                              age=tolower(trimws(gsub(":","",age))),
                                              privateins=tolower(trimws(gsub(":","",privateins))))]
agevector <- c("19 to 25 years",
               "26 to 34 years",
               "35 to 44 years",
               "45 to 54 years",
               "55 to 64 years")
acs5_privateins <- unique(acs5_privateins[age %in% agevector,
                                          ][,tot:=sum(estimate,na.rm=TRUE),by=c("year","GEOID","privateins")
                                            ][,c("year","GEOID","tot","privateins")])

# Transpose wide
privateinsvector <- c("with private health insurance",
                      "no private health insurance")
codevector <- c(1,0)
acs5_privateins <- acs5_privateins %>%
  mutate(privateins = codevector[match(privateins, privateinsvector)]) # encode
acs5_privateins <- acs5_privateins %>% # transpose wide
  pivot_wider(names_from = privateins, 
              values_from = tot,
              names_prefix = "privateins")
privateinsvars <- mixedsort(names(acs5_privateins)[grep("^privateins",names(acs5_privateins))]) # labeling the variables
privateinsvars <- rev(mixedsort(privateinsvars)) # reverse vector order 
for (i in seq_along(privateinsvars)) {
  label(acs5_privateins[[privateinsvars[i]]]) <- privateinsvector[i]
}
# acs5_privateins$privateins_sum <- rowSums(acs5_privateins[, privateinsvars], na.rm = TRUE)

# Share employed (^C23002A; do not break down by civilian v. army. population 16 to 64 years old)
acs5_empstat_raw <- dataacs5[grepl("^C23002A",variable),
                            ][,label2:=gsub("Estimate!!Total:","",label)
                              ][(grepl(".*!!.*!!.*!!.*!!",label2) & grepl("In Armed Forces",label2)) | 
                                grepl(".*!!.*!!.*!!.*!!.*!!",label2) |
                                  (grepl("Not in labor force",label2)),]

acs5_empstat <- acs5_empstat_raw[, c("null","gender","age","inlaborforce","armystat","empstat") := tstrsplit(label2, "!!")
                     ][,null:=NULL
                       ][,`:=` (gender=tolower(trimws(gsub(":","",gender))),
                                age=tolower(trimws(gsub(":","",age))),
                                inlaborforce=tolower(trimws(gsub(":","",inlaborforce))),
                                armystat=tolower(trimws(gsub(":","",armystat))),
                                empstat=tolower(trimws(gsub(":","",empstat))))]
acs5_empstat <- acs5_empstat %>% 
  mutate(empstat = if_else(armystat=='in armed forces',"employed",empstat)) %>% 
  mutate(empstat = if_else(inlaborforce=='not in labor force',"not in labor force",empstat)) 
  
agevector <- c("16 to 64 years")
acs5_empstat <- unique(acs5_empstat[age %in% agevector,
                                    ][,tot:=sum(estimate,na.rm=TRUE),by=c("year","GEOID","empstat")
                                      ][,c("year","GEOID","tot","empstat")])

# Transpose wide
empstatvector <- c("not in labor force",
                   "employed",
                   "unemployed")
codevector <- c(2,1,0)
acs5_empstat <- acs5_empstat %>%
  mutate(empstat = codevector[match(empstat, empstatvector)]) # encode
acs5_empstat <- acs5_empstat %>% # transpose wide
  pivot_wider(names_from = empstat, 
              values_from = tot,
              names_prefix = "empstat")
empstatvars <- mixedsort(names(acs5_empstat)[grep("^empstat",names(acs5_empstat))]) # labeling the variables
empstatvars <- rev(mixedsort(empstatvars)) # reverse vector order 
for (i in seq_along(empstatvars)) {
  label(acs5_empstat[[empstatvars[i]]]) <- empstatvector[i]
}

# Median household income (B19013)
acs5_medinc <- dataacs5[grepl("^B19013",variable),
                        ][concept=="MEDIAN HOUSEHOLD INCOME IN THE PAST 12 MONTHS (IN 2021 INFLATION-ADJUSTED DOLLARS)",]
setnames(acs5_medinc,"estimate","medinc")
acs5_medinc <- unique(acs5_medinc[,c("year","GEOID","medinc")])

# Percent in poverty (B17001)
acs5_poverty_raw <- dataacs5[grepl("^B17001",variable),
                            ][,label2:=gsub("Estimate!!Total:","",label)
                              ][concept=='POVERTY STATUS IN THE PAST 12 MONTHS BY SEX BY AGE',
                                ][grepl(".*!!.*!!.*!!",label2),]

acs5_poverty <- acs5_poverty_raw[, c("null","povertystat","gender","age") := tstrsplit(label2, "!!")
                                 ][,null:=NULL
                                   ][,`:=` (povertystat=tolower(trimws(gsub(":","",povertystat))),
                                            gender=tolower(trimws(gsub(":","",gender))),
                                            age=tolower(trimws(gsub(":","",age))))]
agevector <- c("18 to 24 years",
               "25 to 34 years",
               "35 to 44 years",
               "45 to 54 years",
               "55 to 64 years")

acs5_poverty <- unique(acs5_poverty[age %in% agevector,
                                    ][,tot:=sum(estimate,na.rm=TRUE),by=c("year","GEOID","povertystat")
                                      ][,c("year","GEOID","tot","povertystat")])
# Transpose wide
povertystatvector <- c("income in the past 12 months below poverty level",
                       "income in the past 12 months at or above poverty level")
codevector <- c(1,0)
acs5_poverty <- acs5_poverty %>%
  mutate(povertystat = codevector[match(povertystat, povertystatvector)]) # encode
acs5_poverty <- acs5_poverty %>% # transpose wide
  pivot_wider(names_from = povertystat, 
              values_from = tot,
              names_prefix = "povertystat")
povertystatvars <- mixedsort(names(acs5_poverty)[grep("^povertystat",names(acs5_poverty))]) # labeling the variables
povertystatvars <- rev(mixedsort(povertystatvars)) # reverse vector order 
for (i in seq_along(povertystatvars)) {
  label(acs5_poverty[[povertystatvars[i]]]) <- povertystatvector[i]
}

# Share manufacturing jobs (civilian population 16+ broken down by types of jobs)
acs5_occupation <- dataacs5[grepl("^C24030",variable),
                            ][,label2:=gsub("Estimate!!Total:","",label)
                              ][grepl(".*!!.*!!",label2),
                                ][!grepl(".*!!.*!!.*!!",label2),]

acs5_civilian <- unique(acs5_occupation[,civilian16plus:=sum(estimate,na.rm=TRUE),by=c("year","GEOID")
                                        ][,c("year","GEOID","civilian16plus")])
var_label(acs5_civilian$civilian16plus) <- "Count of Employed Civilians 16+"

acs5_manufacture <- unique(acs5_occupation[grepl("Manufacturing",label2),
                                           ][,manufacture:=sum(estimate,na.rm=TRUE),by=c("year","GEOID")
                                             ][,c("year","GEOID","manufacture")])
var_label(acs5_manufacture$manufacture) <- "Count of Employed Civilians 16+ with Manufacturing Jobs"

# Population (B01003)
acs5_population <- dataacs5[grepl("^B01003",variable),]
acs5_population <- acs5_population[,.(year,GEOID,estimate)]
setnames(acs5_population,"estimate","population")
var_label(acs5_population$population) <- "Total Population, All Ages"

# ===================================================
# MERGE INTO A COUNTY-YEAR LEVEL DATASET
# ===================================================
geoyearlist <- unique(dataacs5[,.(year,GEOID,NAME)])
mlist <- list(geoyearlist,
              acs5_gender,
              acs5_age,
              acs5_race,
              acs5_educ,
              acs5_empstat,
              acs5_medinc,
              acs5_poverty,
              acs5_anyins,
              acs5_privateins,
              acs5_civilian,
              acs5_manufacture,
              acs5_population)

county_acs5 <- Reduce(function(x, y) merge(x, y, by = c("year","GEOID"), all = TRUE), mlist)

setnames(county_acs5,"GEOID","county")
save(county_acs5, file = paste0(rootdir,"local_area_characteristics/output/county_acs5.RData"),compress=TRUE)
write_dta(county_acs5, path = paste0(rootdir,"local_area_characteristics/output/county_acs5.dta"))

# EOF

