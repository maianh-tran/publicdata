/*-------------------------------------------------------------restrict_data.do
*/

qui do ~/Dropbox/publicdata/pos_from_cms/control.do nodata

use ${output}/restricted_1984_2024.dta, clear
keep prov_num year *prov_addr *prov_city *prov_zip_cd *prov_state_cd 
gsort year prov_num

/*
----------------------------------------

Merge variable 

----------------------------------------
*/
gen merge_address = strtrim(stritrim(prov_addr + " " + prov_city + " " + prov_state_cd + " " + prov_zip_cd))
label variable merge_address "A variable for merging back with original data"

// define kind
cap drop kind
cap label drop kind
qui gen kind = .

#delimit ;
label define label_kind
	 1  " 1: having both zip and address" 
	 2  " 2: missing zip but have address"
	 3  " 3: missing address but have zip"
	 4  " 4: missing both zip and address", replace;
#delimit cr
label val kind label_kind
label variable kind "Have both zip and address/missing something"

replace kind = 1 if !mi(prov_zip_cd) & !mi(prov_addr)
replace kind = 2 if mi(prov_zip_cd) & !mi(prov_addr)
replace kind = 3 if mi(prov_addr) & !mi(prov_zip_cd)
replace kind = 4 if mi(prov_zip_cd) & mi(prov_addr)

keep prov* merge_address kind 
drop prov_num 
gduplicates drop 

save ${output}/geocoding_input_restricted_1984_2024.dta, replace

exit

// isolate the DC cases - missed these in first iteration 
use ${output}/geocoding_input_restricted_1984_2024.dta, clear
keep if prov_state_cd == "DC"

save ${output}/geocoding_input_restricted_1984_2024_DC.dta, replace 



