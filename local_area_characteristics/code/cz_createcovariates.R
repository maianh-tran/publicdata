library(tidycensus)
library(dplyr)
library(tidyverse)
library(openxlsx)
library(data.table)
library(haven)
library(labelled)

rm(list=ls())
rootdir <- "~/Dropbox/publicdata/"

# ==========================================
# CREATE COVARIATES
# ==========================================
load(file = paste0(rootdir, "local_area_characteristics/temp/cz_combined.RData"))
cz_measures <- copy(cz_combined)[, 
                                 `:=`(
                                     share_female = gender2 / (gender1 + gender2), # share female
                                     share_age1 = age1 / (age1 + age2 + age3 + age4 + age5),
                                     share_age5 = age5 / (age1 + age2 + age3 + age4 + age5),
                                     share_white = race1 / (race1 + race2 + race3 + race4 + race5 + race6 + race7),
                                     share_black = race2 / (race1 + race2 + race3 + race4 + race5 + race6 + race7),
                                     share_college = (educ5 + educ6 + educ7) / (educ1 + educ2 + educ3 + educ4 + educ5 + educ6 + educ7),
                                     share_unemp = empstat0 / (empstat0 + empstat1),
                                     measure_medinc_k = medinc / 1000,
                                     share_poverty = povertystat1 / (povertystat1 + povertystat0),
                                     share_anyins = anyins1 / (anyins1 + anyins0),
                                     share_privateins = privateins1 / (privateins1 + privateins0),
                                     share_manufacture = manufacture / civilian16plus,
                                     measure_popdens = popdens,
                                     share_rep_voting = candidatevotesrep/totalvotes,
                                     share_popua = poppct_urban)
                                 ]

var_label(cz_measures$share_female) <- "Share of population who are female"
var_label(cz_measures$share_age1) <- "Share of population who are 18-24 years old"
var_label(cz_measures$share_age5) <- "Share of population who are 55-64 years old"
var_label(cz_measures$share_white) <- "Share of population who are white (not including hispanic/latino)"
var_label(cz_measures$share_black) <- "Share of population who are black"
var_label(cz_measures$share_college) <- "Share of population with at least college degree (associate degree and above)"
var_label(cz_measures$share_unemp) <- "Share of population 16-64 years old in the labor force who are not employed"
var_label(cz_measures$measure_medinc_k) <- "Median household income in thousand"
var_label(cz_measures$share_poverty) <- "Share of population who are below poverty line in the past 12 months"
var_label(cz_measures$share_anyins) <- "Share of population who have any kind of health insurance"
var_label(cz_measures$share_privateins) <- "Share of population who have private health insurance"
var_label(cz_measures$share_manufacture) <- "Share of civilian population 16 yo+ who work in manufacturing"
var_label(cz_measures$measure_popdens) <- "Population Density per Square Mile"
var_label(cz_measures$share_rep_voting) <- "Share voted for Republican Party"
var_label(cz_measures$share_popua) <- "Share of population living in urban area"

# order columns 
id_cols <- c("cz20","year")
share_cols <- grep("^share_", names(cz_measures), value = TRUE)
measure_cols <- grep("^measure_", names(cz_measures), value = TRUE)
first_cols <- c(id_cols,share_cols,measure_cols)
other_cols<- setdiff(names(cz_measures),first_cols)
new_order <- c(first_cols,other_cols)
setcolorder(cz_measures,new_order)

# save out
write_dta(cz_measures, paste0(rootdir, "local_area_characteristics/output/cz_covariates.dta"))

# EOF #
