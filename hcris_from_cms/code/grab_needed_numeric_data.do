/*-------------------------------------------------------------grab_needed_data.do
*/

qui do ~/Dropbox/publicdata/hcris_from_cms/control.do nodata

use if inlist(wksht_cd,"G300000","S300001") using ${temp}/processed_numeric_data_1996_2022.dta, clear

cap drop field 
gen field = ""

/*
------------------------------------------

Revenue

------------------------------------------
*/
// see R23P240f.pdf page 120
loc rev_wks "G300000"

// Total patient revenues
replace field = "tot_rev" if cost_report == "2552-96" & wksht_cd == "`rev_wks'" & clmn_num == "0100" & line_num == 100 
replace field = "tot_rev" if cost_report == "2552-10" & wksht_cd == "`rev_wks'" & clmn_num == "00100" & line_num == 100

// Net patient revenues
replace field = "net_rev" if cost_report == "2552-96" & wksht_cd == "`rev_wks'" & clmn_num == "0100" & line_num == 300
replace field = "net_rev" if cost_report == "2552-10" & wksht_cd == "`rev_wks'" & clmn_num == "00100" & line_num == 300

/*
------------------------------------------

Beds

------------------------------------------
*/
// see R23P240f.pdf page 9
loc bed_wks "S300001"

// Hospital Adults & Peds.
replace field = "tot_adult_ped_m_swing_bed" if cost_report == "2552-96" & wksht_cd == "`bed_wks'" & clmn_num == "0100" & line_num == 100 
replace field = "tot_adult_ped_m_swing_bed" if cost_report == "2552-10" & wksht_cd == "`bed_wks'" & clmn_num == "00200" & line_num == 100 

// Total Adults and Peds. 
replace field = "tot_adult_ped_bed" if cost_report == "2552-96" & wksht_cd == "`bed_wks'" & clmn_num == "0100" & line_num == 500 
replace field = "tot_adult_ped_bed" if cost_report == "2552-10" & wksht_cd == "`bed_wks'" & clmn_num == "00200" & line_num == 700

// Total
replace field = "tot_bed" if cost_report == "2552-96" & wksht_cd == "`bed_wks'" & clmn_num == "0100" & line_num == 1200 
replace field = "tot_bed" if cost_report == "2552-10" & wksht_cd == "`bed_wks'" & clmn_num == "00200" & line_num == 1400

// Total bed count can be broken down into Total Adults and Peds., Intensive Care Unit, Coronary Care Unit, Burn Intensive Care Unit, Surgical Intensive Care Unit, Other Special Care, Nursery
// These can be pulled easily

// reshape wide 
keep if !mi(field)
keep rpt_rec_num itm_val_num year field
gisid rpt_rec_num year field

ren itm_val_num v_
reshape wide v, i(rpt_rec_num year) j(field) string
ren v_* * 

/*
------------------------------------------

Clean fields

------------------------------------------
*/
assert !mi(rpt_rec_num)
tostring rpt_rec_num, replace 
assert strlen(rpt_rec_num) <= 6
replace rpt_rec_num = "00000" + rpt_rec_num
replace rpt_rec_num = substr(rpt_rec_num,-6,.)

/*
------------------------------------------

Save out 

------------------------------------------
*/
label variable tot_rev "Total Revenue (Sheet G300000, Ln 1, Col 1)"
label variable net_rev "Total Revenue (Sheet G300000, Ln 3, Col 1)"
label variable tot_adult_ped_m_swing_bed "Total Adults and Peds. Minus Swing Beds (Sheet S300001, Ln 100, Col 1 <2010 & Col 2 >=2010)"
label variable tot_adult_ped_bed "Total Adults and Peds.  (Sheet S300001, Ln 500 & Col 1 <2010 and Ln 700 & Col 2 >=2010"
label variable tot_bed "Total Beds (Sheet S300001, Ln 1200 & Col 1 <2010 and Ln 1400 & Col 2 >=2010"

order rpt_rec_num year *rev *bed* 
gsort rpt_rec_num year

ren rpt_rec_num report_rec_num
save ${temp}/restricted_vars_1996_2022.dta, replace

exit 


