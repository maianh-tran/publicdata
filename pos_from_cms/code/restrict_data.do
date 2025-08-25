/*-------------------------------------------------------------restrict_data.do
*/

qui do ~/Dropbox/publicdata/pos_from_cms/control.do nodata

use ${output}/processed_1984_2024.dta, clear

// Only hospitals
keep if prov_cd == 1

// Only in continental U.S. + Alaska and Hawaii
preserve 
	import excel using "${raw}/statefips.xlsx", sheet("list") firstrow clear
	keep if strpos(status,"State;") | strpos(status,"Federal district")

	gunique state_cd 
	assert `r(unique)' == 51
	
	keep state_cd 
	ren state_cd prov_state_cd
	
	tempfile keptstates
	save `keptstates', replace
restore 

merge m:1 prov_state_cd using `keptstates', keep(3) nogen

save ${output}/restricted_1984_2024.dta, replace

exit


