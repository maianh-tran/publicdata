clear all

cd "~/Dropbox/pricegrowth/databuild/Medicare OPPS CPTs"
global path  	"`c(pwd)'"
global code 	"${path}/code"
global output 	"${path}/output"
global temp 	"${path}/temp"
global raw		"${path}/rawdata"

/*	----------------------------

Read in updated lists of HCPCS codes

------------------------------- */

// cap confirm file "$temp/add_b.dta"
if _rc!=0 {
	
	clear all 
	save "$temp/add_b.dta", emptyok replace 
	
// 	local c = 0
	forvalues q = 1/4 {	
	forvalues yr = 2011/2023 {
// 		loc q 4
// 		loc yr 2019
		display `yr'

		cd "$raw/Q`q'/`yr'"		
		local folder: dir . dirs "*"
		
		foreach i of local folder {
			di "`i'"
			//	Identify the Excel spreadsheet 
			cd "$raw/Q`q'/`yr'/`i'"
			fs "*.xlsx"
			loc length: word count `r(files)'	
			di `length'
			cap assert `length'==1
			if _rc==0 {
				local add_b `r(files)'			
			}
			if _rc!=0 {
				fs "*.XLSX"
				loc length: word count `r(files)'	
				di `length'
				assert `length'==1
				local add_b `r(files)'
			}

			//	Read in spreadsheet
			display "Importing `add_b' ..."
			import excel using "`add_b'", clear firstrow

			//	Drop the all missing 
			findname, all(missing(@)) 
			loc w: word count `r(varlist)'
			cap assert `w' > 0 
			if _rc==0 {
				drop `r(varlist)'		
			}
		}	
		
			//	Replace variable names 
			cap confirm variable HCPCSCode
			if _rc!=0 {
			drop if A == ""	//	Drop the blank rows	
			foreach v of varlist * {
			   local vname = strtoname(`v'[1])
			   rename `v' `vname'
			}
			keep if _n>1			
			}
			
			//	Clean variable names 
			foreach var of varlist * {
				rename `var' `=strlower("`var'")'
			}
			
			keeporder *apc* *si* *hcpcs*code* **minimum*unadjusted* *national*unadjusted* *payment*rate* *relative*weight* *si* *short*desc*
			ren *apc* apc 
			ren *hcpcs*code* hcpcs
			ren *minimum*unadjusted* min_unadj_copay
			ren *national* nat_unadj_copay
			ren *payment*rate* pmt_rate
			ren *relative*weight* rel_wgt
			ren *si* si
			ren *short*desc* desc
			
			gen year = `yr'
			gen quarter = `q'

			ds year, not
			foreach var of varlist `r(varlist)' {
				tostring `var',replace
				replace `var' = ustrtrim(strtrim(`var'))
			}
			
			append using "$temp/add_b.dta"
			save "$temp/add_b.dta", replace	
		}					
	}
}	
// }

/*	----------------------------

Clean variables

------------------------------- */

use "$temp/add_b.dta",clear 

keeporder year quarter hcpcs desc apc si desc rel_wgt pmt_rate nat_unadj_copay min_unadj_copay 

gen strlen = strlen(hcpcs)
drop if strlen == 0 | strlen > 10
drop strlen
compress

destring rel_wgt pmt_rate nat_unadj_copay min_unadj_copay, replace

gsort hcpcs year quarter
save "$output/add_b_hcpcs.dta", replace

// These are really HCPCS codes
// Separately save the subset that start with numbers: the CPT codes

gen is_cpt = regexm(hcpcs, "^[0-9]")
keep if is_cpt == 1
drop is_cpt
rename hcpcs cpt

gsort cpt year quarter
save "$output/add_b_cpts.dta", replace	// Note this functions as a crosswalk from CPTs to APCs

exit




















































