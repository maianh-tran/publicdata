/*-------------------------------------------------------------process_geocoding_output.do
*/

qui do ~/Dropbox/publicdata/pos_from_cms/control.do nodata

/*
----------------------------------------

Without DC

----------------------------------------
*/
import delimited using "${rootdir}/received/20250421 - from MS - geocoded/geocoded_table_mai anh.csv", clear

keep score match_addr x y user* 
ren user_* *

tempfile nodc 
save `nodc', replace 

/*
----------------------------------------

DC

----------------------------------------
*/
import delimited using "${rootdir}/received/20250508- from MS - geocoded/geocoded_table_mai anh_DC.csv", clear
keep score match_addr x y prov_addr prov_city prov_zip_cd prov_state_cd 

// clean the zip code 
tostring prov_zip_cd, replace 
assert strlen(prov_zip_cd) == 5

append using `nodc'

/*
----------------------------------------

A field to merge back onto original data

----------------------------------------
*/
gen merge_address = strtrim(stritrim(prov_addr + " " + prov_city + " " + prov_state_cd + " " + prov_zip_cd))

keep if score > 0 // excluded the non-geocodable 

// dups because match scores are different - only 1 instance
gduplicates tag merge_address, gen(temp_d)
count if temp_d 
assert `r(N)' == 2
drop temp* 

// just keep the first one
gsort merge_address -score
by merge_address: keep if _n==1 

keep merge_address x y score
gduplicates drop 
gisid merge_address

ren x prov_lon 
ren y prov_lat 
ren score diag_geocoded_score 

label variable prov_lat "Provider Latitude" 
label variable prov_lon "Provider Longitude" 
label variable diag_geocoded_score "How good is the geocoding?" 

save ${temp}/geocoded_output.dta, replace

exit


