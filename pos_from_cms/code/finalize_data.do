/*-------------------------------------------------------------finalize_data.do
*/

qui do ~/Dropbox/publicdata/pos_from_cms/control.do nodata

/*
----------------------------------------

Merge geocoding output onto main file

----------------------------------------
*/
use ${output}/restricted_1984_2024.dta, clear

gen merge_address = strtrim(stritrim(prov_addr + " " + prov_city + " " + prov_state_cd + " " + prov_zip_cd))
label variable merge_address "A variable for merging back with original data"

merge m:1 merge_address using ${temp}/geocoded_output.dta, keep(1 3) 
drop merge_address

gen diag_geocoded_status = 1 if _merge == 3
replace diag_geocoded_status = 0 if _merge == 1 
drop _merge 

// label the variables
#d ;
label define diag_geocoded_status
	 0  " 0: could not be geocoded" 
	 1  " 1: geocoded", replace;
#d cr
label val diag_geocoded_status diag_geocoded_status
label variable diag_geocoded_status "Could this address be geocoded?" 

// save out
order year prov*, first
order orig* diag*, last
drop prov_state_fips
save ${output}/finalized_hospitals_1984_2024.dta, replace

exit


