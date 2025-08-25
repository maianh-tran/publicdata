/*-------------------------------------------------------------unzip_data.do
*/

qui do ~/Dropbox/publicdata/hcris_from_cms/control.do nodata

/*
------------------------------------------

Unzip

------------------------------------------
*/
// forms 2552-10
forvalues y=2010/2022 {
	cap mkdir "${raw}/HOSP10FY`y'" 
	cd "${raw}/HOSP10FY`y'"
	unzipfile "${raw}/downloaded_zipfiles/HOSP10FY`y'", replace
}

// forms 2552-96
forvalues y=1996/2011 {
	cap mkdir "${raw}/HOSPFY`y'" 
	cd "${raw}/HOSPFY`y'"
	unzipfile "${raw}/downloaded_zipfiles/HOSPFY`y'", replace
}

/*
------------------------------------------

Turn csv to Stata

------------------------------------------
*/
qui {
// forms 2552-10
forvalues y=2010/2022 {
	di in red "`y'"
	cd "${raw}/HOSP10FY`y'" 
	loc myfilelist: dir . files "*.CSV"
	foreach f of loc myfilelist {
		loc stata_file = subinstr("`f'",".CSV",".dta",.)
		cap confirm file "${raw}/HOSP10FY`y'/`stata_file'"
		if _rc!=0 {
			import delimited "`f'", clear
			save "${raw}/HOSP10FY`y'/`stata_file'", replace  			
		}
	}
}

// forms 2552-96
forvalues y=1996/2011 {
	di in red "`y'"
	cd "${raw}/HOSPFY`y'" 
	loc myfilelist: dir . files "*.CSV"
	foreach f of loc myfilelist {
		loc stata_file = subinstr("`f'",".CSV",".dta",.)
		cap confirm file "${raw}/HOSPFY`y'/`stata_file'"
		if _rc!=0 {
			import delimited "`file'", clear
			save "${raw}/HOSPFY`y'/`stata_file'", replace  			
		}
	}
}
}

exit

