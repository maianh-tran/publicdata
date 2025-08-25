/*-------------------------------------------------------------create_fy_cy_prep.do
*/

qui do ~/Dropbox/publicdata/hcris_from_cms/control.do nodata

use ${temp}/hcris_restricted_vars_1996_2022.dta, clear 

/*
------------------------------------------

Some tools

------------------------------------------
*/
// # of days in the FY
foreach v in begin end {
	gen temp_`v'_m = substr(fy_`v'_dt,1,2)
	gen temp_`v'_d = substr(fy_`v'_dt,4,2)
	gen temp_`v'_y = substr(fy_`v'_dt,7,.)
	destring temp_`v'_*, replace
	
	ren fy_`v'_dt fy_`v'_dt_str
	gen fy_`v'_dt = mdy(temp_`v'_m,temp_`v'_d,temp_`v'_y)
	format fy_`v'_dt %tdnn/dd/CCYY
}

gen temp_fy_days = fy_end_dt - fy_begin_dt + 1

// report period for each provider (e.g., "01/01 of beginning year to 12/31 of ending year", "07/01 of beginning year to 06/31 of ending year")
gen temp_begin_month = substr(fy_begin_dt_str,1,5)
gen temp_end_month = substr(fy_end_dt_str,1,5)

gen temp_period = temp_begin_month + " of year t to " + temp_end_month + " of year t or t+1"

// how many FULL FY definition each provider has? (defined as a report period of 365 or 366 days)
cap drop temp_full_fy
gen temp_begin_y_t1 = temp_begin_y + 1
gen temp_fy_begin_dt_t1 = mdy(temp_begin_m,temp_begin_d,temp_begin_y_t1)
replace temp_begin_d = 28 if temp_begin_d == 29 & mi(temp_fy_begin_dt_t1)
replace temp_fy_begin_dt_t1 = mdy(temp_begin_m,temp_begin_d,temp_begin_y_t1) if mi(temp_fy_begin_dt_t1)
gen temp_full_fy = (temp_fy_begin_dt_t1 - fy_end_dt) == 1	

cap drop ct*
preserve 
	keep prov_num temp_period temp_full_fy
	gduplicates drop 
	qbys prov_num: gen ct_all_period = _N
	qbys prov_num: egen ct_good_fy_period = sum(temp_full_fy)
	list if prov_num == "490084"
	keep prov_num ct_good_fy_period ct_all_period
	gduplicates drop 	
	tabulate ct_good_fy_period ct_all_period, cell
	
	tempfile ct_full_period 
	save `ct_full_period', replace
restore  

merge m:1 prov_num using `ct_full_period', assert(3) nogen 

// flag provider/years with dups 
cap drop temp_have_dup*
qbys prov_num year: gen temp_have_dup0 = _n > 1
qbys prov_num: egen temp_have_dup = max(temp_have_dup0)
drop temp_have_dup0

save ${temp}/temp_hcris_restricted_vars_1996_2022.dta, replace 

/*
------------------------------------------

View some examples 

------------------------------------------
*/
use ${temp}/temp_hcris_restricted_vars_1996_2022.dta, clear

cap drop temp_cond
gen temp_cond = temp_have_dup & inrange(ct_good_fy_period,2,2) & ct_all_period == 3  // condition for the examples. the perfect case is ct_good_fy_period == 1 & ct_all_period == 1 & !temp_have_dup

examples(1)

exit 
