/*-------------------------------------------------------------deduplicate.do
*/

qui do ~/Dropbox/publicdata/hcris_from_cms/control.do nodata

use ${temp}/temp_hcris_restricted_vars_1996_2022.dta, clear

// ren year raw_year
list prov_num *year *fy_*dt *net_rev *tot_bed  if prov_num == "530032", ab(32) sepby(*year)	

/*
------------------------------------------

Deduplicate

------------------------------------------
*/
// if multiple obs same year and all form a full period when combined -> combine (673025) 
qbys prov_num year: egen temp_max_wt_year = max(fy_end_dt)
qbys prov_num year: egen temp_min_wt_year = min(fy_begin_dt)

gen temp_min_wt_yeart1= mdy(month(temp_min_wt_year), day(temp_min_wt_year), year(temp_min_wt_year)+1)
format temp_*_wt_year* %tdnn/dd/CCYY

// multiple obs same year, and some or all form a full period when combined -> combine
// mostly 2nd and 3rd obs 
cap drop temp_ct
qbys prov_num year: gen temp_ct = _N 

qbys prov_num year (fy_begin_dt): gen temp_beg_wt_year = fy_begin_dt[2] if temp_ct ==3 & inrange(_n,2,3)
qbys prov_num year (fy_begin_dt): gen temp_end_wt_year = fy_end_dt[_N] if temp_ct ==3 & inrange(_n,2,3)

gen temp_beg_wt_yeart1= mdy(month(temp_beg_wt_year), day(temp_beg_wt_year), year(temp_beg_wt_year)+1)
format temp_*_wt_year* %tdnn/dd/CCYY

cap drop temp_cond
gen temp_cond = ((temp_min_wt_yeart1 - temp_max_wt_year == 1) & temp_ct > 1)
examples(5)

replace temp_cond = 1 if temp_cond == 0 & ((temp_beg_wt_yeart1 - temp_end_wt_year == 1) & temp_ct == 3)
examples(5)
 
foreach v of varlist *rev {
	ren `v' orig_`v'
	qbys prov_num year temp_cond: egen `v' = sum(orig_`v') if temp_cond
	replace `v' = orig_`v' if !temp_cond
	drop orig_`v'
}

foreach v of varlist *bed {
	ren `v' orig_`v'
	qbys prov_num year temp_cond (fy_begin_dt): gen `v' = orig_`v'[_N] if temp_cond
	replace `v' = orig_`v' if !temp_cond
	drop orig_`v'
}

bys prov_num year temp_cond (fy_begin_dt): replace fy_begin_dt = fy_begin_dt[1] if temp_cond
bys prov_num year temp_cond (fy_begin_dt): replace fy_end_dt = fy_end_dt[_N] if temp_cond

drop temp*
keep prov_num *year *rev *bed fy_*_dt
gduplicates drop 

// if multiple obs same year, keep the one with the full period 
cap drop temp_ct
qbys prov_num year: gen temp_ct = _N 

gen temp_fy_begin_dt_t1 = mdy(month(fy_begin_dt),day(fy_begin_dt),(year(fy_begin_dt)+1))
assert day(fy_begin_dt) == 29 & month(fy_begin_dt) == 2 if mi(temp_fy_begin_dt_t1)
replace temp_fy_begin_dt_t1 = mdy(month(fy_begin_dt),day(fy_begin_dt) - 1,(year(fy_begin_dt)+1)) if mi(temp_fy_begin_dt_t1)
gen temp_full_fy = temp_fy_begin_dt_t1 - fy_end_dt == 1

cap drop temp_cond*
gen temp_cond0 = (temp_full_fy & temp_ct > 1)
qbys prov_num year: egen temp_cond = max(temp_cond0)
examples(5)

drop if temp_cond & temp_full_fy != 1

// drop if only have 1 year and dups still
cap drop temp_ct
qbys prov_num year: gen temp_ct = _N 

cap drop temp_first*
qbys prov_num year: gen temp_first = _n==1 
qbys prov_num: egen temp_first_years = sum(temp_first)

cap drop temp_cond
gen temp_cond = temp_first_years == 1 & temp_ct > 1
examples(5)
drop if temp_cond

// 2 partial in the first year: drop first
cap drop temp_ct
qbys prov_num year: gen temp_ct = _N 

cap drop temp_min_yr
qbys prov_num: egen temp_min_yr = min(year)
cap drop temp_cond 
qbys prov_num (fy_begin_dt): gen temp_cond = year == temp_min_yr & temp_ct == 2 & _n == 1
examples(5)
drop if temp_cond

// 2 partial in the last year: drop last
cap drop temp_ct
qbys prov_num year: gen temp_ct = _N 
 
cap drop temp_max_yr
qbys prov_num: egen temp_max_yr = max(year)
cap drop temp_cond 
qbys prov_num (fy_begin_dt): gen temp_cond = year == temp_max_yr & temp_ct == 2 & _n == _N
examples(5)
drop if temp_cond

//  if two obs and no year gap, pick the period with more days in the year
cap drop temp_ct
qbys prov_num year: gen temp_ct = _N 

gen temp_year_end = mdy(12,31,year)
gen temp_year_start = mdy(1,1,year)

generate temp_overlap = min(fy_end_dt,temp_year_end)-max(fy_begin_dt,temp_year_start)+1
replace temp_overlap = 0 if temp_overlap<0

qbys prov_num (year): gen temp_nogap = temp_ct == 2 &	///
									   (year == year[_n-1] + 1 | year == year[_n-2] + 1) &	///
									   (year == year[_n+1] - 1 | year == year[_n+2] - 1)

cap drop temp_cond 
qbys prov_num year (temp_overlap): gen temp_cond = _n == 1 & temp_ct == 2 & temp_overlap[_N] > temp_overlap[1] & temp_nogap
qbys prov_num year (temp_overlap): replace temp_cond = 1 if _n == 1 & temp_ct == 2 & temp_overlap[_N] == temp_overlap[1] & temp_nogap // pick the later one if breaking tie 
examples(5)
drop if temp_cond

// if two obs and there is a year gap, assign the second obs to the missing year 
cap drop temp_ct
qbys prov_num year: gen temp_ct = _N 

cap drop temp_cond 
qbys prov_num year (fy_begin_dt): gen temp_cond = !temp_nogap & temp_ct==2 
examples(5)
qbys prov_num (year): replace year = year + 1 if temp_cond & year == year[_n+1] - 2
qbys prov_num (year): replace year = year - 1 if temp_cond & year == year[_n-1] + 2

// remaining ones are too complicated - manually adjust
cap drop temp_ct
qbys prov_num year: gen temp_ct = _N 
cap drop temp_cond*
gen temp_cond = temp_ct > 1
cap log close 
log using "${temp}/dups/complicated.log", replace 
examples(0)
log close 
gunique prov_num if temp_cond

# d ;
foreach prov_num in 
440026
381308
340049
192035
180134
110186
010032
{
;
#d cr
qbys prov_num year (fy_begin_dt): replace fy_begin_dt = fy_begin_dt[1] if prov_num == "`prov_num'" & temp_cond
qbys prov_num year (fy_begin_dt): replace fy_end_dt = fy_end_dt[_N] if prov_num == "`prov_num'" & temp_cond

foreach v of varlist *rev {
	ren `v' orig_`v'
	qbys prov_num year temp_cond: egen `v' = sum(orig_`v') if temp_cond & prov_num == "`prov_num'"
	replace `v' = orig_`v' if !temp_cond
	drop orig_`v'
}

foreach v of varlist *bed {
	ren `v' orig_`v'
	qbys prov_num year temp_cond (fy_begin_dt): gen `v' = orig_`v'[_N] if temp_cond & prov_num == "`prov_num'"
	replace `v' = orig_`v' if !temp_cond
	drop orig_`v'
}
}

drop temp*
keep prov_num *year *rev *bed fy_*_dt
gduplicates drop 

replace year = 2004 if year == 2003 & prov_num == "171357"
replace year = 2009 if year == 2008 & prov_num == "171357" & year(fy_end_dt) == 2009	// this one does not have an obs for 2010

qbys prov_num year (fy_begin_dt): drop if inrange(_n,1,2) & prov_num == "193074" & year == 2007

replace year = year + 1 if year < 2018 & year > 2000 & prov_num == "200018"
replace year = 2001 if year == 2002 & year(fy_end_dt) == 2001 & prov_num == "200018"

replace year = year + 1 if inrange(year,2001,2016) & prov_num == "200041" 
replace year = 2001 if year(fy_end_dt) == 2001 & prov_num == "200041"

drop if inlist(prov_num, "260021","260176") & year(fy_begin_dt) == year(fy_end_dt) & inrange(year(fy_end_dt), 1996,1997)

// no more dups 
cap drop temp_ct
qbys prov_num year: gen temp_ct = _N 
cap drop temp_cond*
gen temp_cond = temp_ct > 1
cap assert temp_cond == 0 
if _rc!=0 {
	di in red "DUPS STILL"
	cap log close 
	log using "${temp}/dups/remains.log", replace 
	examples(0)
	log close 	
	gunique prov_num if temp_cond
}
if _rc==0 di in red "NO MORE DUPS"

drop temp* 

/*
------------------------------------------

Adjust revenue and beds 

------------------------------------------
*/
// keep beds same
// but pro-rate revenue 
gen temp_no_days_master = mdy(12,31,year) - mdy(1,1,year)
gen temp_no_days_period = fy_end_dt - fy_begin_dt

foreach v of varlist *rev {
	ren `v' orig_`v'
	gen `v' = orig_`v' * (temp_no_days_master / temp_no_days_period)
	
	label variable orig_`v' "Original field"
	label variable `v' "Prorated to full calendar year"
}

/*
------------------------------------------

Checks

------------------------------------------
*/
// check for year gaps 
cap drop temp_cond
qbys prov_num (year): gen temp_cond = (year!=year[_n+1] - 1 & _n!=_N) | (year!=year[_n-1] + 1 & _n!=1) 
examples(10)

drop temp* 
gsort prov_num year

save ${output}/hcris_1996_2022.dta, replace

exit 




