clear all 
cap cd 
global rootdir "~/Dropbox/publicdata"

/*
----------------------------------------------------

County level vote count

----------------------------------------------------
*/
// Load data 
import delimited using "${rootdir}/local_area_characteristics/rawdata/electionresults/countypres_2000-2020.csv",clear

// Limit to post 2012
keep if year>=2012

// Process county_fips
assert !mi(county_fips) | mi(county_fips) if inlist(county_name,"DISTRICT OF COLUMBIA","FEDERAL PRECINCT","MAINE UOCAVA","STATEWIDE WRITEIN")

replace county_fips = 11001 if county_name=="DISTRICT OF COLUMBIA"
assert mi(county_fips) if inlist(county_name,"FEDERAL PRECINCT","MAINE UOCAVA","STATEWIDE WRITEIN")
drop if mi(county_fips) 

tostring county_fips, replace
replace county_fips = "0" + county_fips if strlen(county_fips) == 4
assert regexm(county_fips, "[0-9][0-9][0-9][0-9][0-9]")

// Process party variables 
isid year county_fips party mode
replace party="OTHER" if !inlist(party,"DEMOCRAT","REPUBLICAN")

// Confirm candidates 
// assert candidate == "BARACK OBAMA" if party == "DEMOCRAT" & year==2008
assert candidate == "BARACK OBAMA" if party == "DEMOCRAT" & year==2012
assert candidate == "HILLARY CLINTON" if party == "DEMOCRAT" & year==2016
assert candidate == "JOSEPH R BIDEN JR" if party == "DEMOCRAT" & year==2020

// assert candidate == "JOHN MCCAIN" if party == "REPUBLICAN" & year==2008
assert candidate == "MITT ROMNEY" if party == "REPUBLICAN" & year==2012
assert candidate == "HILLARY CLINTON" if party == "DEMOCRAT" & year==2016
assert inlist(candidate,"DONALD TRUMP","DONALD J TRUMP") if party == "REPUBLICAN" & inlist(year,2016,2020)

replace candidate = "OTHER" if party == "OTHER" 

// Create short versions
gen party_short = "dem" if party == "DEMOCRAT"
replace party_short = "rep" if party == "REPUBLICAN"
replace party_short = "oth" if party == "OTHER"

// Confirm sum of all modes
bys year county_fips: egen test_totalvotes=sum(candidatevotes)
assert test_totalvotes==totalvotes
drop test_totalvotes

// Limit to relevant variables and reshape wide
rename candidatevotes candidatevotes0
bys year county_fips party_short totalvotes: egen candidatevotes=sum(candidatevotes0)

keeporder year county_fips county_name party_short candidatevotes totalvotes
duplicates drop

bys year county_fips: egen test_totalvotes=sum(candidatevotes)
assert test_totalvotes==totalvotes
drop test_totalvotes

reshape wide candidatevotes, i(year county_fips county_name totalvotes) j(party_short) str
rename county_fips county

// Impute some missing 
insobs 3

// One county in Hawaii (https://en.wikipedia.org/wiki/2020_United_States_presidential_election_in_Hawaii)
replace year=2012 if _n==_N-2 
replace county="15005" if _n==_N-2 
replace county_name="KALAWAO" if _n==_N-2 
replace totalvotes=27 if _n==_N-2 
replace candidatevotesdem=25 if _n==_N-2 
replace candidatevotesrep=2 if _n==_N-2 
replace candidatevotesoth=0 if _n==_N-2 

replace year=2016 if _n==_N-1 
replace county="15005" if _n==_N-1 
replace county_name="KALAWAO" if _n==_N-1 
replace totalvotes=20 if _n==_N-1 
replace candidatevotesdem=14 if _n==_N-1 
replace candidatevotesrep=1 if _n==_N-1 
replace candidatevotesoth=5 if _n==_N-1 

replace year=2020 if _n==_N 
replace county="15005" if _n==_N 
replace county_name="KALAWAO" if _n==_N
replace totalvotes=24 if _n==_N 
replace candidatevotesdem=23 if _n==_N 
replace candidatevotesrep=1 if _n==_N 
replace candidatevotesoth=0 if _n==_N

tempfile county_level
save `county_level', replace

/*
----------------------------------------------------

Flag

----------------------------------------------------
*/

loc f county 
use ``f'_level', clear
foreach v of varlist candidate* {
	assert !mi(`v')
}

// Election shares 
gen voted_dem=candidatevotesdem/totalvotes 
gen voted_rep=candidatevotesrep/totalvotes 

// Flag places that voted for Republican/Democrat candidates 
gen f_dem_plurality = candidatevotesdem > candidatevotesrep & candidatevotesdem > candidatevotesoth
gen f_rep_plurality = candidatevotesrep > candidatevotesdem & candidatevotesrep > candidatevotesoth

order `f'

compress 
save "${rootdir}/local_area_characteristics/output/`f'_election_results.dta", replace	

exit

// 46113 changed to 46102 in 2013. change to harmonize with crosswalk later
replace county = "46113" if county=="46102"	

merge m:1 county using `crosswalk', assert(1 3) keep(3) nogen

/*
----------------------------------------------------

Load county to CZ crosswalk

----------------------------------------------------
*/
import delimited using "${rootdir}/crosswalk_spatial/output/ziptocountytocz.csv",clear
gisid zip
tostring county, replace
replace county="00000" + county 
replace county=substr(county,-5,.)
keep county cz20 
gduplicates drop

tempfile crosswalk 
save `crosswalk', replace 

/*
----------------------------------------------------

Commuting zone level vote count

----------------------------------------------------
*/
// aggregate 
gcollapse (sum) totalvotes candidatevotesdem candidatevotesoth candidatevotesrep, by(cz year)
drop if mi(cz)
tempfile cz_level
save `cz_level', replace


/*
----------------------------------------------------

If ever needed, code for Hawaii

----------------------------------------------------
*/
