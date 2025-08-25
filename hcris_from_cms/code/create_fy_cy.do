/*-------------------------------------------------------------create_fy_cy.do
*/

qui do ~/Dropbox/publicdata/hcris_from_cms/control.do nodata

/*
------------------------------------------

Raw data

------------------------------------------
*/
use ${temp}/temp_hcris_restricted_vars_1996_2022.dta, clear
keeporder report_rec_num year prov_num fy_*dt *rev* *bed*
drop no_*

tempfile raw 
save `raw', replace

// example for documentation
keeporder report_rec_num year prov_num fy_*dt net_rev tot_rev tot_bed
gsort year fy_begin_dt
list if prov_num == "530032", ab(32) sepby(year)	

/*
------------------------------------------

Create a FY/provider number dataset

------------------------------------------
*/
// grab most frequent FY available for each provider
use ${temp}/temp_hcris_restricted_vars_1996_2022.dta, clear
keep if temp_full_fy
contract prov_num temp_period temp_begin_month temp_end_month 
qbys prov_num (_freq): keep if _n==_N 
keep prov_num temp_period temp_begin_month temp_end_month 

tempfile most_freq_fy 
save `most_freq_fy', replace
	
// grab latest FY available for each provider
use ${temp}/temp_hcris_restricted_vars_1996_2022.dta, clear
keep if temp_full_fy
qbys prov_num temp_period: egen temp_max_yr = max(year)
keep prov_num temp_period temp_begin_month temp_end_month temp_max_yr
gduplicates drop 
qbys prov_num (temp_max_yr): keep if _n == _N 
keep prov_num temp_period temp_begin_month temp_end_month 

tempfile latest_fy 
save `latest_fy', replace	

// confirm: 90% overlap between the two 
use prov_num temp_period using `latest_fy', clear
merge 1:1 prov_num temp_period using  `most_freq_fy'
foreach m in 1 2 3 {
	gunique prov_num if _m == `m'
	loc m`m' = `r(unique)'
}
assert (`m1'/(`m1' + `m3')) < 0.1	// 90% overlap

// grab list of providers and years
use ${temp}/temp_hcris_restricted_vars_1996_2022.dta, clear
keep prov_num fy_begin_dt fy_end_dt
qbys prov_num: egen min_dt = min(fy_end_dt)
qbys prov_num: egen max_dt = max(fy_end_dt)
foreach v in min max {
	gen `v'_year0 = year(`v'_dt)
	qbys prov_num: egen year`v' = max(`v'_year0)
}
keep prov_num yearmin yearmax
gduplicates drop 
	
reshape long year, i(prov_num) j(which) str
drop which 
gduplicates drop 

fillin prov_num year
gen temp_group = _fillin == 0
qbys prov_num (year): gen group = sum(temp_group)
qbys prov_num group: keep if group == 1 | (group==2 & _n==1)
list in 1/30, sepby(prov_num)
keep prov_num year

tempfile prov_num 
save `prov_num'

// create a provider/financial year end/financial year period dataset
// using the latest FY available for each provider
use `prov_num', clear 
merge m:1 prov_num using `latest_fy', assert (1 3)
replace temp_begin_month = "01/01" if _m == 1
replace temp_end_month = "12/31" if _m == 1
gen imputed_full_fy = _m==1
drop temp_period

foreach v in begin end {
	gen temp_`v'_m = substr(temp_`v'_month,1,2)
	gen temp_`v'_d = substr(temp_`v'_month,4,2)
	destring temp_`v'_m, replace 
	destring temp_`v'_d, replace 
	drop temp_`v'_month		
}

gen yeartm1 = year - 1 

foreach y in year yeartm1 {
	foreach v in begin end {
		gen temp_range_`v'_`y' = mdy(temp_`v'_m,temp_`v'_d,`y')
	}
}

// leap year 
replace temp_begin_d = 28 if temp_begin_d == 29 & mi(temp_range_begin_year)
replace temp_end_d = 28 if temp_end_d == 29 & mi(temp_range_end_year)

foreach y in year yeartm1 {
	foreach v in begin end {
		replace temp_range_`v'_`y' = mdy(temp_`v'_m,temp_`v'_d,`y') if mi(temp_range_`v'_`y')
	}
}

gen fy_begin_dt = temp_range_begin_year if temp_range_begin_year < temp_range_end_year
replace fy_begin_dt = temp_range_begin_yeartm1 if temp_range_begin_year > temp_range_end_year
gen fy_end_dt = temp_range_end_year
format fy_* %tdnn/dd/CCYY
format temp_range_* %tdnn/dd/CCYY

assert !mi(fy_begin_dt) & !mi(fy_end_dt)	
keep prov_num year fy*
list if prov_num == "530032", ab(32)	

keep prov_num year fy*dt 
tempfile master_rollup_fy 
save `master_rollup_fy', replace

/*
------------------------------------------

Create a CY/provider number dataset or FFY/provider number dataset

------------------------------------------
*/
use ${temp}/temp_hcris_restricted_vars_1996_2022.dta, clear
keep prov_num fy_begin_dt fy_end_dt

qbys prov_num: egen min_dt = min(fy_begin_dt)
qbys prov_num: egen max_dt = max(fy_end_dt)
foreach v in min max {
	gen `v'_year0 = year(`v'_dt)
	qbys prov_num: egen year`v' = max(`v'_year0)
}
keep prov_num yearmin yearmax
gduplicates drop 
	
reshape long year, i(prov_num) j(which) str
drop which 
gduplicates drop 

fillin prov_num year
gen temp_group = _fillin == 0
qbys prov_num (year): gen group = sum(temp_group)
qbys prov_num group: keep if group == 1 | (group==2 & _n==1)

gen cy_begin_dt = mdy(1,1,year)
gen cy_end_dt = mdy(12,31,year)
gen ffy_begin_dt = mdy(1,10,year)
gen ffy_end_dt = mdy(9,30,year)
format *dt %tdnn/dd/CCYY	

foreach y in cy ffy {
	preserve
	keep prov_num year `y'*dt 
// 	list in 1/30, sepby(prov_num)

	tempfile master_rollup_`y' 
	save `master_rollup_`y''
	restore
}
 	
/*
------------------------------------------

Pull in data within the FY/CY/FFY

------------------------------------------
*/
// foreach y in fy cy ffy {
	loc y fy
	use `master_rollup_`y'', clear 
	ren `y'_*_dt master_`y'_*_dt
	rangejoin fy_begin_dt master_`y'_begin_dt master_`y'_end_dt using `raw', by(prov_num)
	drop *_U

	tempfile begin`y'
	save `begin`y'', replace

	use `master_rollup_`y'', clear 
	ren `y'_*_dt master_`y'_*_dt
	rangejoin fy_end_dt master_`y'_begin_dt master_`y'_end_dt using `raw', by(prov_num)
	drop *_U

	append using `begin`y''
	gduplicates drop 
	gsort prov_num master_`y'_begin_dt master_`y'_end_dt

	gen temp_nonmiss0 = !mi(fy_begin_dt)	// drop missing if having at least 1 non-missing 
	qbys prov_num: egen temp_nonmiss = max(temp_nonmiss0)
	drop if mi(fy_begin_dt) & temp_nonmiss 
	drop temp_nonmiss*

	order report_rec_num, first 
	order fy_begin_dt fy_end_dt, after (master_`y'_end_dt)
	list if prov_num == "530032", ab(32) sepby(master_`y'_begin_dt)	

	/*
	------------------------------------------

	Merge on and impute 

	------------------------------------------
	*/
	// then, impute revenue/bed/etc for each FY/provider number
	gen no_days = min(master_`y'_end_dt, fy_end_dt) - max(master_`y'_begin_dt, fy_begin_dt) + 1
	assert inrange(no_days,1,366)

	gen master_no_days = master_`y'_end_dt - master_`y'_begin_dt + 1

	gen ratio_days = no_days / master_no_days

	// for revenue: pro-rate by the number of days
	list report_rec_num prov_num year *net_rev *tot_rev *tot_bed *fy_*dt if prov_num == "530032", ab(32) sepby(master_*_begin_dt)	

	foreach v of varlist *rev {
		gen allo_`v' = `v' * ratio_days
	}

	// for bed: grab the latest 
	gsort prov_num year master_`y'_begin_dt master_`y'_end_dt fy_begin_dt fy_end_dt
	foreach v of varlist *bed {
		qbys prov_num master_`y'_begin_dt master_`y'_end_dt: gen allo_`v' = `v'[_N]
	}

	// example
	list prov_num year *fy_*dt *net_rev *tot_bed  if prov_num == "530032", ab(32) sepby(master_*_begin_dt)	
	
	// collapse 
	gcollapse (nansum) all*rev (max) allo*bed, by (prov_num year master_*_begin_dt master_*_end_dt)	
	ren allo_* * 

	list prov_num year *fy_*dt *net_rev *tot_bed  if prov_num == "530032", ab(32) sepby(master_*_begin_dt)	
	
	save ${output}/hcris_`y'_1996_2022.dta, replace
}

exit


