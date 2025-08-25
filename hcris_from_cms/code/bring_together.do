/*-------------------------------------------------------------bring_together.do
*/

qui do ~/Dropbox/publicdata/hcris_from_cms/control.do nodata

use ${temp}/cleaned_report_data_1996_2022.dta, clear
destring year, replace 

merge 1:1 year report_rec_num using ${temp}/restricted_vars_1996_2022.dta, assert(1 3) 

gen no_reported_bed_revenue = _m == 1
label variable no_reported_bed_revenue "No bed and revenue data reported"
drop _m 

order report_rec_num year prov_num *bed* *rev*, first
order no_reported_bed_revenue, last
gsort prov_num year
save ${temp}/hcris_restricted_vars_1996_2022.dta, replace

exit 


