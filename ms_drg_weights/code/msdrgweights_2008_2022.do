/*
HC_ext_cms_msdrgweights_2008_2017.do
Hao Nguyen
Date Created: 03/19/2020
Date Updated: 05/10/2021 by EC 
Date Updated: 01/24/2025 by MT 
*/

clear all 
cap cd 
global rootdir "~/Dropbox/publicdata"
* ----------------------------------------------------------------------------------------
* This do-file cleans and creates MS DRG weights dataset from 2008 to 2022.
* ----------------------------------------------------------------------------------------
local counter = 0

loc minyr 2007
loc maxyr 2022

forval yr = `minyr'/`maxyr' {
   di in red "`counter' `yr'"
   
   if `yr' <= 2012 import excel using ${rootdir}/ms_drg_weights/rawdata/FY_`yr'_drg_weights.xls, firstrow clear
		 
   if `yr' == 2007 {
		ren DRG msdrg
		ren Weights weights
   }

   if `yr' > 2012 & `yr' <= 2022 {
     import excel using ${rootdir}/ms_drg_weights/rawdata/FY_`yr'_drg_weights.xlsx, firstrow clear 
     rename *, lower
	 drop if _n == 1
	 rename (table5list g) (msdrg weights)
	 replace weights = "0" if inlist(msdrg,"998","999")
   }
   
   cap rename *,lower
   
   keep msdrg weights
   drop if missing(weights)
      
   destring *, replace
   gen merge_year = `yr'

   rename (msdrg weights) (merge_drg drg_wgt)
   
   if `counter' > 0 append using ${rootdir}/ms_drg_weights/output/msdrgweights_`minyr'_`maxyr'.dta
   local ++counter
   
   sort merge_year merge_drg
   compress
   
   save ${rootdir}/ms_drg_weights/output/msdrgweights_`minyr'_`maxyr'.dta, replace
}
