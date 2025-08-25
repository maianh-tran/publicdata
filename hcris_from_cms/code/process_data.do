/*-------------------------------------------------------------process_data.do
*/

qui do ~/Dropbox/publicdata/hcris_from_cms/control.do nodata

/*
------------------------------------------

Report table

------------------------------------------
*/
cap confirm file ${temp}/processed_report_data_1996_2022.dta
if _rc!=0 {
clear all 
di in red "report"

// grab variable names and labels 
d using ${raw}/downloaded_stata_files/hosp_rpt2552_10_2010.dta, varlist 
loc new_names "`r(varlist)'"
di "`new_names'"

// forms 2552-10
forvalues y=2010/2022 {
	di in red "`y'"
	use "${raw}/HOSP10FY`y'/HOSP10_`y'_RPT.dta", clear
	d, varlist
	loc old_names "`r(varlist)'"
	di "`old_names'"
	
	ren (`old_names') (`new_names')
	
	gen year = `y'
	gen cost_report = "2552-10"
	
	tostring *, replace 
	
	save "${temp}/2552-10_`y'_RPT.dta", replace
}

// forms 2552-96
forvalues y=1996/2011 {
	di in red "`y'"
	use "${raw}/HOSPFY`y'/hosp_`y'_RPT.dta", clear
	d, varlist
	loc old_names "`r(varlist)'"
	di "`old_names'"
	
	ren (`old_names') (`new_names')
	
	gen year = `y'
	gen cost_report = "2552-96"
	
	tostring *, replace 

	save "${temp}/2552-96_`y'_RPT.dta", replace
}

cd ${temp}
fs "2552-*_RPT.dta"
append using `r(files)'
save ${temp}/processed_report_data_1996_2022.dta, replace

// erase in temp folder when done 
local files : dir . files "2552-*_RPT.dta"
foreach f of local files {
   erase "`f'"
}
}

/*
------------------------------------------

Numeric table

------------------------------------------
*/
qui {
cap confirm file ${temp}/processed_numeric_data_1996_2022.dta
if _rc!=0 {
clear all 
di in red "numeric"

// grab variable names and labels 
d using ${raw}/downloaded_stata_files/hosp_nmrc2552_10_2010_long.dta, varlist 
loc new_names "`r(varlist)'"
di "`new_names'"

// forms 2552-10
forvalues y=2010/2022 {
	di in red "`y'"
	cap confirm file "${temp}/2552-10_`y'_NMRC.dta" 
	if _rc!=0 {
	use "${raw}/HOSP10FY`y'/HOSP10_`y'_NMRC.dta", clear
	d, varlist
	loc old_names "`r(varlist)'"
	di "`old_names'"
	
	ren (`old_names') (`new_names')
	
	gen year = `y'
	gen cost_report = "2552-10"
	
	save "${temp}/2552-10_`y'_NMRC.dta", replace
	}
}

// forms 2552-96
forvalues y=1996/2011 {
	di in red "`y'"
	cap confirm file "${temp}/2552-96_`y'_NMRC.dta" 
	if _rc!=0 {
	use "${raw}/HOSPFY`y'/hosp_`y'_NMRC.dta", clear
	d, varlist
	loc old_names "`r(varlist)'"
	di "`old_names'"
	
	ren (`old_names') (`new_names')
	
	gen year = `y'
	gen cost_report = "2552-96"
	
	save "${temp}/2552-96_`y'_NMRC.dta", replace
	}
}

cle
cd ${temp}
fs "2552-*_NMRC.dta"
append using `r(files)'
save ${temp}/processed_numeric_data_1996_2022.dta, replace

// erase in temp folder when done 
local files : dir . files "2552-*_NMRC.dta"
foreach f of local files {
   erase "`f'"
}
}
}
/*
------------------------------------------

Alphanumeric table 

------------------------------------------
*/
cap confirm file ${temp}/processed_alphanumeric_data_1996_2022.dta
if _rc!=0 {
clear all 
di in red "alphanumeric"

// grab variable names and labels 
d using ${raw}/downloaded_stata_files/hosp_alpha2552_10_2010_long.dta, varlist
loc new_names "`r(varlist)'"
di "`new_names'"

// forms 2552-10
forvalues y=2010/2022 {
	di in red "`y'"
	cap confirm file "${temp}/2552-10_`y'_ALPHA.dta" 
	if _rc!=0 {
	use "${raw}/HOSP10FY`y'/HOSP10_`y'_ALPHA.dta", clear
	d, varlist
	loc old_names "`r(varlist)'"
	di "`old_names'"
	
	ren (`old_names') (`new_names')
	
	gen year = `y'
	gen cost_report = "2552-10"
	
	save "${temp}/2552-10_`y'_ALPHA.dta", replace
	}
}

// forms 2552-96
forvalues y=1996/2011 {
	di in red "`y'"
	cap confirm file "${temp}/2552-96_`y'_ALPHA.dta" 
	if _rc!=0 {
	use "${raw}/HOSPFY`y'/hosp_`y'_ALPHA.dta", clear
	d, varlist
	loc old_names "`r(varlist)'"
	di "`old_names'"
	
	ren (`old_names') (`new_names')
	
	gen year = `y'
	gen cost_report = "2552-10"
	
	save "${temp}/2552-96_`y'_ALPHA.dta", replace
	}
}

cd ${temp}
fs "2552-*_ALPHA.dta"
append using `r(files)'
save ${temp}/processed_alphanumeric_data_1996_2022.dta, replace

// erase in temp folder when done 
local files : dir . files "2552-*_ALPHA.dta"
foreach f of local files {
   erase "`f'"
}
}


exit 


