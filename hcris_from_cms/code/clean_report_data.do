/*-------------------------------------------------------------clean_report_data.do
*/

qui do ~/Dropbox/publicdata/hcris_from_cms/control.do nodata

use ${temp}/processed_report_data_1996_2022.dta,clear 

ren (prvdr_* *rpt* *bgn*) (prov_* *report* *begin*)

/*
------------------------------------------

Clean fields

------------------------------------------
*/
// the provider numbers
foreach v in report_rec_num prov_num {
	assert !mi(`v')
	assert strlen(`v') <= 6
	replace `v' = "00000" + `v'
	replace `v' = substr(`v',-6,.)
}

// npi is always misisng - drop 
assert npi == "." | npi == "0"
drop npi 

/*
------------------------------------------

Save out

------------------------------------------
*/
order report_rec_num year prov_* fy_* proc_dt cost_report
gsort prov_num year 
gduplicates drop 

save ${temp}/cleaned_report_data_1996_2022.dta, replace

exit 


