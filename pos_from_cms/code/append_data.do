/*-------------------------------------------------------------append_data.do
*/

qui do ~/Dropbox/publicdata/pos_from_cms/control.do nodata

loc minyr 1984
loc maxyr 2024

/*
-----------------------------------

Get list of files

-----------------------------------
*/
// list of files to import
cap erase "${temp}/raw_files_list.dta"
filelist, dir ("${raw}/Provider of Services File - Hospital & Non-Hospital Facilities") pattern("*.csv") save("${temp}/raw_files_list.dta") 

// process this list and put into a local
use "${temp}/raw_files_list.dta", clear

// keep Q4 if there are multiple quarters available. otherwise keep the year version
keep if regexm(dirname,"^.*/[0-9][0-9][0-9][0-9].*Q4$") |	///
		regexm(dirname,"^.*[0-9][0-9][0-9][0-9]$")

// confirm one file each year 
gen year = regexs(1) if regexm(dirname,"^.*([0-9][0-9][0-9][0-9]).*")
gisid year
destring year, replace
keep if inrange(year,`minyr',`maxyr')

// get full path
gen full_path = dirname + "/" + filename
glevelsof full_path, loc(full_paths)

/*
-----------------------------------

Append all files 

-----------------------------------
*/
// clear 
// tempfile master 
// save `master', emptyok 

foreach full_path of loc full_paths {
	loc year = substr(subinstr("`full_path'","/Users/mt2275/Dropbox/publicdata/pos_from_cms/rawdata/Provider of Services File - Hospital & Non-Hospital Facilities/","",.),1,4)
	di in red "`year'"

	cap confirm file "${temp}/temp_year`year'.dta"
	if _rc!=0 {
	
	import delimited using "`full_path'", clear
// 	import delimited using "`full_path'", rowrange(10000:10010) clear

	gen year = "`year'"

	if `year' > = 1984 & `year' < 1991  {
		rename prov1680 prvdr_num
		rename prov0475	fac_name
		rename prov2720 st_adr		
		rename prov2905 zip_cd
		rename prov0100 chow_dt
		rename xrefprov cross_ref_provider_number
		rename category prvdr_ctgry_cd
		rename state_region state_rgn_cd
// 		rename prov2700 ssa_state_cd
// 		rename prov0095 chow_cnt
// 		rename state state_fips // this one is not really hospital state
		rename prov0115 city_state
	}

	if `year' == 1991  {
		rename prov1680 prvdr_num
		rename prov0475	fac_name
		rename prov2720 st_adr
		rename fipstate state_fips 
		rename prov0115 city_state
		rename prov2905 zip_cd
		rename prov0100 chow_dt
		rename prov0300 cross_ref_provider_number
		rename prov0085 prvdr_ctgry_sbtyp_cd
		rename prov0075 prvdr_ctgry_cd
		rename prov0655 mdcd_vndr_num
		rename prov1565 orgnl_prtcptn_dt
// 		rename prov4770 pgm_trmntn_cd
		rename prov1670 pgm_prtcptn_cd
		rename prov2885 gnrl_cntl_type_cd
		rename prov2710 state_rgn_cd
// 		rename prov2700 ssa_state_cd
		rename prov0095 chow_cnt
	}

	if `year' > = 1992 & `year' <= 1993 {
		rename prov1680 prvdr_num
		rename prov0475	fac_name
		rename prov2720 st_adr
		rename prov3225 city_name
		rename prov2905 zip_cd
		rename prov3230 state_cd
		rename prov0100 chow_dt
		rename prov0300 cross_ref_provider_number
		rename prov0085 prvdr_ctgry_sbtyp_cd
		rename prov0075 prvdr_ctgry_cd
		rename prov0655 mdcd_vndr_num
		rename prov1565 orgnl_prtcptn_dt
// 		rename prov4770 pgm_trmntn_cd
		rename prov1670 pgm_prtcptn_cd
		rename prov2885 gnrl_cntl_type_cd
		rename prov2710 state_rgn_cd
// 		rename prov2700 ssa_state_cd
		rename prov0095 chow_cnt
	}
	
	if `year' > 1993 & `year' < 2011 {
		rename prov1680 prvdr_num
		rename prov0475	fac_name
		rename prov2720 st_adr
		rename prov3225 city_name
		rename prov2905 zip_cd
		rename prov3230 state_cd
		rename prov0100 chow_dt
		rename prov0300 cross_ref_provider_number
		rename prov0085 prvdr_ctgry_sbtyp_cd
		rename prov0075 prvdr_ctgry_cd
		rename prov0655 mdcd_vndr_num
		rename prov1565 orgnl_prtcptn_dt
		rename prov4770 pgm_trmntn_cd
		rename prov1670 pgm_prtcptn_cd
		rename prov2885 gnrl_cntl_type_cd
// 		rename prov2700 ssa_state_cd
		rename prov0095 chow_cnt
	}

#d ; 
foreach v in year 
			 prvdr_num 
			 fac_name
			 prvdr_ctgry_sbtyp_cd
			 prvdr_ctgry_cd
			 st_adr
			 city_name
			 zip_cd
			 state_cd
			 state_fips
			 chow_dt
			 gnrl_cntl_type_cd
			 cross_ref_provider_number
			 prvdr_ctgry_sbtyp_cd
			 prvdr_ctgry_cd
			 mdcd_vndr_num
			 orgnl_prtcptn_dt
			 pgm_trmntn_cd
			 pgm_prtcptn_cd 
			 state_rgn_cd
			 chow_cnt
			 city_state
			 {
			 ;
#d cr	
				 
	cap confirm variable `v'
	if _rc!=0 {
		di in red "`v' not existing"
		gen `v' = "" 
		}
				 }

	keeporder ///
		year	///
		prvdr_num fac_name prvdr_ctgry_sbtyp_cd prvdr_ctgry_cd ///
		st_adr city_name zip_cd state_cd state_fips state_rgn_cd city_state ///
		chow_dt chow_cnt gnrl_cntl_type_cd ///
		cross_ref_provider_number	///
		prvdr_ctgry_sbtyp_cd prvdr_ctgry_cd	///
		mdcd_vndr_num	///
		orgnl_prtcptn_dt pgm_trmntn_cd pgm_prtcptn_cd 

	tostring *, replace
	
	ds 
	foreach v in `r(varlist)' {
		replace `v' = "" if `v' == "."
	}
	
	save "${temp}/temp_year`year'"
// 	append using `master'
// 	save `master', replace 
}
}

// append 
clear 
cd "${temp}"
fs "temp_year*.dta"
append using `r(files)'

// rename some variables
ren cross_ref_provider_number xref 
ren prvdr* prov*
ren prov_ctgry_cd prov_cd 
ren prov_ctgry_sbtyp_cd prov_sub_cd 
ren orgnl_prtcptn_dt first_part_dt 
ren pgm_trmntn_cd pgm_term_cd
ren pgm_prtcptn_cd pgm_part_cd 
ren gnrl_cntl_type_cd owner_cd 
ren mdcd_vndr_num mdr_vendor_num 
ren fac_name prov_name 
ren st_adr prov_addr
ren city_name prov_city
ren zip_cd prov_zip_cd
ren state_cd prov_state_cd 
ren city_state prov_city_state 
ren state_fips prov_state_fips

// label the variables
label variable year 						"Year"
label variable prov_num 					"Provider CMS Certification Number (CCN)"				
label variable prov_name 					"Provider Name"
label variable prov_addr						"Provider Street Address"
label variable prov_city					"Provider City"
label variable prov_zip_cd						"Provider Zip Code"
label variable prov_state_cd						"Provider State"
label variable prov_city_state					"Provider City and State"
label variable chow_dt						"Effective date of the most recent change of ownership for this provider" 
label variable chow_cnt						"Count of times of ownership change (missing prior to 1991)"
label variable xref							"Cross reference provider number"
label variable prov_cd						"Provider Type ID"
label variable prov_sub_cd					"Provider Subtype ID (missing prior to 1991)"
label variable first_part_dt	 			"Original Participation Date (missing prior to 1991)"
label variable pgm_term_cd					"Termination Code (missing prior to 1994)"
label variable pgm_part_cd					"Program Participation Code (missing prior to 1991)"
label variable owner_cd						"Ownership Type (missing prior to 1991)"
label variable mdr_vendor_num 				"Medicare Vendor Number (missing prior to 1991)"
label variable state_rgn_cd					"State/Region Code" 
label variable prov_state_fips				"State fips (only available in 1991)"

// any more variables to pull? 
destring year, replace 
save "${temp}/appended_`minyr'_`maxyr'", replace

exit


