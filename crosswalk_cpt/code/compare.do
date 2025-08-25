/*	-----------------------------------------------------------------------------

Compare with crosswalk imported into server

-------------------------------------------------------------------------- */

clear all

cd "~/Dropbox/pricegrowth/databuild/Medicare OPPS CPTs"
global path  	"`c(pwd)'"
global code 	"${path}/code"
global output 	"${path}/output"
global temp 	"${path}/temp"
global raw		"${path}/rawdata"

/*	----------------------------

Compare

------------------------------- */

//	read in updated
use "$output/add_b_hcpcs.dta", clear
keep if inrange(year,2011,2022)	//	period of old one
keep apc desc hcpcs year

joinby _all using "/Users/mt2275/Dropbox/Yale Health Economics Data/Medicare OPPS CPTs/deriveddata/add_b_hcpcs.dta", unmatched(both)

e
















































