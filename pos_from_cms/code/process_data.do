/*-------------------------------------------------------------process_data.do
*/

qui do ~/Dropbox/publicdata/pos_from_cms/control.do nodata

use "${temp}/appended_1984_2024.dta", clear

/*
-----------------------------------

These variables did not exist in older years

-----------------------------------
*/
#d
foreach v in prov_sub_cd
			 first_part_dt
			 pgm_part_cd
			 owner_cd
			 mdr_vendor_num
			 {;
#d cr
	di in red "`v'"
	assert mi(`v') if year < 1991
			 }

#d
foreach v in pgm_term_cd
			 {;
#d cr
	di in red "`v'"
	assert mi(`v') if year < 1994
			 }

#d
foreach v in prov_city
			 prov_state_cd
			 {;
#d cr
	di in red "`v'"
	assert mi(`v') if year <= 1990
			 }
			 
/*
-----------------------------------

These variables did not exist in later years

-----------------------------------
*/
#d
foreach v in prov_city_state
			 prov_state_fips
			 {;
#d cr
	di in red "`v'"
	assert mi(`v') if year > 1991 
			 }

/*
-----------------------------------

Clean provider numbers

-----------------------------------
*/
#d
foreach v in prov_num
			 xref
			 {;
#d cr
	di in red "Cleaning `v'"
	gen orig_`v' = `v'
	
	// drop the invalid provider numbers 
	if "`v'" == "prov_num" assert regexm(prov_city,"LE CREATION DATE.*") if mi(`v')
	list if `v'=="0"
	if "`v'" == "prov_num" assert mi(prov_name) & mi(prov_addr) & mi(prov_city) & mi(prov_zip_cd) & mi(prov_state_cd) if `v'=="0"
	if "`v'" == "xref" {
		assert year==1984 if `v'=="0" 
		assert year <= 1990 if `v' == "Õ"
	}
	
	if "`v'" == "prov_num" drop if mi(`v') | `v'=="0" | `v' == "000000"
	if "`v'" == "xref" replace `v' = "" if mi(`v') | `v'=="0" | `v' == "Õ"

	// reformat provider IDs: 6 or 10 digits
	replace `v' = subinstr(`v'," ","",.)
	if "`v'" == "prov_num" assert regexm(`v',"[0-9A-Z]+")		
	if "`v'" == "xref" assert regexm(`v',"[0-9A-Z]+") | mi(`v')
	replace `v' = "0000" + `v' if strlen(`v') == 2
	replace `v' = "000" + `v' if strlen(`v') == 3
	replace `v' = "00" + `v' if strlen(`v') == 4	// the length 2, 3, 4 may be typos - adding 0's for now
	replace `v' = "0" + `v' if strlen(`v') == 5
	replace `v' = "00" + `v' if strlen(`v') == 8
	replace `v' = "0" + `v' if strlen(`v') == 9
	gen temp_len_`v' = strlen(`v')
	
	if "`v'" == "xref" assert year <= 1990 if !inlist(temp_len_`v',0,6,10)
	if "`v'" == "prov_num" assert inlist(temp_len_`v',6,10)
			 }

/*
-----------------------------------

Clean dates

-----------------------------------
*/
#d
foreach v in chow_dt
			 first_part_dt
			 {;
#d cr
	di in red "Cleaning `v'"
	// some dates are YYYYMMDD strings
	cap drop temp*
	gen orig_`v'=`v'
	ren `v' temp_`v'0
	replace temp_`v'0 = subinstr(temp_`v'0," ","",.)
	assert inlist(temp_`v'0,"0","00","00000","Õ","MMDDYY") if !(regexm(temp_`v'0,"^[1-9][0-9]+") | mi(orig_`v'))
	destring year, replace
	assert inrange(year,1984,1991) if !(regexm(temp_`v'0,"^[1-9][0-9]+") | mi(temp_`v'0))
	replace temp_`v'0 = "" if !(regexm(temp_`v'0,"^[1-9][0-9]+") | mi(temp_`v'0))
	gen temp_len_`v' = strlen(temp_`v'0)

	gen temp_`v'_year = substr(temp_`v'0,1,4) 
	gen temp_`v'_month = substr(temp_`v'0,5,2)
	gen temp_`v'_day = substr(temp_`v'0,7,2)
	destring temp_`v'_*, replace 

	gen temp_`v'1 = mdy(temp_`v'_month,temp_`v'_day,temp_`v'_year) if temp_len_`v' == 8

	// some dates are YYMMDD strings
	drop temp_`v'_year temp_`v'_month temp_`v'_day
	gen temp_`v'_year = substr(temp_`v'0,1,2) 
	if "`v'" == "chow_dt" assert year < 2000 if temp_len_`v' == 6
	replace temp_`v'_year = "19" + temp_`v'_year
	gen temp_`v'_month = substr(temp_`v'0,3,2)
	gen temp_`v'_day = substr(temp_`v'0,5,2)
	destring temp*, replace 

	gen temp_`v'2 = mdy(temp_`v'_month,temp_`v'_day,temp_`v'_year) if temp_len_`v' == 6

	gen `v' = temp_`v'1 if !mi(temp_`v'1)
	assert mi(temp_`v'1) if !mi(temp_`v'2)
	replace `v' = temp_`v'2 if !mi(temp_`v'2)

	// some weird dates - just keep as missing 
	assert inrange(year,1984,1991) if mi(`v') & !mi(temp_`v'0)
	su year if mi(`v') & !mi(temp_`v'0)
	if "`v'" == "chow_dt" assert `r(N)'== 39 
	if "`v'" == "first_part_dt" assert `r(N)'== 4 

	format `v' %td	
}

label variable chow_dt 						"Change of owndership date"
label variable first_part_dt 				"Original Participation Date"
drop temp*

/*
-----------------------------------

Clean zip codes

-----------------------------------
*/
gen orig_prov_zip_cd = prov_zip_cd

// zips with letters - errors 
assert inrange(year,1984,1990) if !regexm(prov_zip_cd ,"[0-9]+") & !mi(prov_zip_cd) 
assert inlist(prov_zip_cd,"A","ADA","ANADA","CANAD","DA") if !regexm(prov_zip_cd ,"[0-9]+") & !mi(prov_zip_cd)
replace prov_zip_cd = "" if !regexm(prov_zip_cd ,"[0-9]+") & !mi(prov_zip_cd)

// length 1 or 2 - likely errors
gen temp_len_prov_zip_cd = strlen(prov_zip_cd)
assert inrange(temp_len_prov_zip_cd,0,5)

assert inrange(year,1984,1990) if temp_len_prov_zip_cd == 1 | temp_len_prov_zip_cd == 2
assert inlist(prov_zip_cd,"0","11","16","4","87") if temp_len_prov_zip_cd == 1 | temp_len_prov_zip_cd == 2

replace prov_zip_cd = "" if inlist(prov_zip_cd,"0","11")
replace prov_zip_cd = "20016" if prov_zip_cd=="16" & year==1984 & prov_num=="09X021"
replace prov_zip_cd = "27104" if prov_zip_cd=="4" & inrange(year,1984,1990) & inlist(prov_num,"345058","34X087","34X096")
replace prov_zip_cd = "28387" if prov_zip_cd=="87" & inrange(year,1984,1990) & inlist(prov_num,"34R015")

// length 3 and 4 - add 0's
replace prov_zip_cd = "00" + prov_zip_cd if temp_len_prov_zip_cd == 3
replace prov_zip_cd = "0" + prov_zip_cd if temp_len_prov_zip_cd == 4

// length 5 are good
assert strlen(prov_zip_cd) == 5 | mi(prov_zip_cd)

/*
-----------------------------------

Extract states 

-----------------------------------
*/
gen orig_prov_state_cd = prov_state_cd

// some weird state codes 
assert year == 2024 if prov_state_cd == "A0"
replace prov_state_cd = "CA" if prov_state_cd == "A0"	// typos

// extract for earlier years
gen orig_prov_city_state = prov_city_state 
replace prov_city_state = subinstr(prov_city_state,"Õ","",.)
replace prov_city_state = subinstr(prov_city_state,",","",.)
replace prov_city_state = subinstr(prov_city_state,".","",.)
replace prov_city_state = subinstr(prov_city_state,"%","",.)
replace prov_city_state = subinstr(prov_city_state,")","",.)
replace prov_city_state = strtrim(stritrim(prov_city_state)) 

// glevelsof prov_city_state if !regexm(prov_city_state,"^[A-Z\s]+$")

gen temp_toimpute_state = regexs(1) if regexm(prov_city_state,"^.* ([A-Z]+)$")
gen temp_toimpute_city = regexs(1) if regexm(prov_city_state,"(^.*) ([A-Z]+)$")

// impute if these are valid states 
preserve 
	import excel using ${raw}/statefips.xlsx, sheet("list") firstrow clear	
	keep state_cd 
	drop if mi(state_cd)
	
	ren state_cd temp_toimpute_state
	
	tempfile valid
	save `valid', replace
restore

merge m:1 temp_toimpute_state using `valid', keep(1 3)
replace prov_state_cd = temp_toimpute_state if _m==3 & mi(prov_state_cd) & !mi(temp_toimpute_state)
replace prov_city = temp_toimpute_city if _m==3 & mi(prov_city) & !mi(temp_toimpute_city)
drop _m 

// some are state names, not state abbreviation 
preserve 
	import excel using ${raw}/statefips.xlsx, sheet("list") firstrow clear	
	keep state_name state_cd 
	drop if mi(state_name)
	replace state_name = upper(strtrim(stritrim(state_name)))	
	ren state_name temp_toimpute_state
	ren state_cd temp_toimpute_state_cd
	tempfile valid2
	save `valid2', replace
restore

cap drop _m
merge m:1 temp_toimpute_state using `valid2', keep(1 3)
replace prov_state_cd = temp_toimpute_state_cd if _m==3 & mi(prov_state_cd) & !mi(temp_toimpute_state_cd)
replace prov_city = temp_toimpute_city if _m==3 & mi(prov_city) & !mi(temp_toimpute_city)
drop _m 

// manually fixing these 
replace prov_state_cd = "CN" if inlist(temp_toimpute_state,"CN","CANADA","CANAD","CAN","CANA") 
replace prov_state_cd = "MX" if inlist(temp_toimpute_state,"MX","MEX") 
replace prov_state_cd = "OK" if inlist(temp_toimpute_state,"OKLA") 
replace prov_state_cd = "MI" if inlist(temp_toimpute_state,"MICHICAN")
replace prov_state_cd = "OR" if inlist(temp_toimpute_state,"ORE")
replace prov_state_cd = "CA" if inlist(temp_toimpute_state,"CALIF")
replace prov_state_cd = "MD" if inlist(temp_toimpute_state,"MARYLAND")
replace prov_state_cd = "CT" if inlist(temp_toimpute_state,"HAVENCT")
replace prov_city = "EAST HAVEN" if inlist(temp_toimpute_state,"HAVENCT")
replace prov_state_cd = "CT" if inlist(temp_toimpute_state,"DEPOTCT")
replace prov_city = "MANSFIELD" if inlist(temp_toimpute_state,"DEPOTCT")
replace prov_state_cd = "PR" if inlist(temp_toimpute_state,"MAYAGQUEZPR")
replace prov_city = "MAYAGQUEZ" if inlist(temp_toimpute_state,"MAYAGQUEZPR")

// what's left? 
// glevelsof prov_city_state if mi(prov_state_cd)
preserve 
	contract prov_addr prov_zip_cd prov_city_state if mi(prov_state_cd)
	list
restore
drop temp* 

// less than 0.3%
count 
loc all = `r(N)'
count if mi(prov_state_cd)
loc miss = `r(N)'
di `miss'
assert(`miss'/`all'*100) <0.03
assert inrange(year,1984,1991) if mi(prov_state_cd)

// the imputed ones are good
assert strlen(prov_state_cd) == 2 if !mi(prov_state_cd)
drop prov_city_state

/*
-----------------------------------

Clean names 

-----------------------------------
*/
foreach v in prov_name {
	gen orig_`v' = `v'
	replace `v' = strtrim(stritrim(`v')) 
}

/*
----------------------------------------

Clean addresses 

----------------------------------------
*/
gen orig_prov_addr = prov_addr
replace prov_addr = strtrim(stritrim(prov_addr)) 

// undo the abbreviation
replace prov_addr = subinstr(prov_addr,"&","AND",.)
replace prov_addr = subinstr(prov_addr,"P O","PO",.)
replace prov_addr = subinstr(prov_addr,"P.O.","PO",.)
replace prov_addr = subinstr(prov_addr,"AVE.","AVENUE",.)
replace prov_addr = subinstr(prov_addr,"AVE,","AVENUE,",.)
replace prov_addr = subinstr(prov_addr,"BLDG","BUILDING",.)
replace prov_addr = subinstr(prov_addr,"STE ","SUITE ",.)
replace prov_addr = subinstr(prov_addr,"DR ","DRIVE ",.)
replace prov_addr = subinstr(prov_addr,"DR,","DRIVE,",.)

// don't care about suites 
replace prov_addr = regexr(prov_addr, ", SUITE.*", "")
replace prov_addr = regexr(prov_addr, "SUITE.*", "")
replace prov_addr = regexr(prov_addr, ", SUI.*", "")
replace prov_addr = regexr(prov_addr, ", ROOM.*", "")
replace prov_addr = regexr(prov_addr, ",.*FLOOR", "")
replace prov_addr = regexr(prov_addr, ",.*FL", "")
replace prov_addr = regexr(prov_addr, ",.*FLOO", "")
replace prov_addr = regexr(prov_addr, ", [0-9]+TH", "")

// trim again 
replace prov_addr = strtrim(stritrim(prov_addr)) 

/*
-----------------------------------

Clean the codes

-----------------------------------
*/
// make these numeric
#d
foreach v in prov_cd
			 prov_sub_cd 
			 {;
#d cr
	gen orig_`v' = `v'
	destring `v', replace
			 }

// keep these as string for now
#d
foreach v in pgm_part_cd
			 pgm_term_cd
			 owner_cd
			 {;
#d cr
			 }

/*
-----------------------------------

Save out 

-----------------------------------
*/
order orig*,last

gsort prov_num year
save ${output}/processed_1984_2024.dta, replace

exit


