/*-------------------------------------------------------------clean_xref.do
*/

qui do ~/Dropbox/publicdata/pos_from_cms/control.do nodata

/*
----------------------------------------

Explore xref field

----------------------------------------
*/
use ${output}/restricted_1984_2024.dta, clear
gsort prov_num year 

// how many unique xref per POS ID 
qbys prov_num xref: gen temp_first= _n==1 & !mi(xref)
qbys prov_num: gen ct_xref = sum(temp_first)

assert ct_xref <= 3 // 3 max 

preserve
	keep prov_num ct_xref
	gduplicates drop 
	su ct_xref,de 
restore

// run some random examples
cap drop temp*
gen temp_cond = ct_xref == 2	// condition for the examples
gunique prov_num if temp_cond
gen temp_sort = runiformint(0,`r(unique)') if temp_cond
bysort prov_num (temp_sort): replace temp_sort = temp_sort[1]

gsort prov_num year 
loc n_example 20	// just view all
glevelsof prov_num if temp_sort <=`n_example', loc(prov_nums)
foreach prov_num of loc prov_nums {
	di in red "`prov_num'"
	list year prov* xref if prov_num == "`prov_num'", sepby(prov_num xref)
}

// grab Yale example 
glevelsof prov_num if (strpos(prov_name,"YALE") & strpos(prov_name,"NEW HAVEN")) | (strpos(prov_name,"RAPHAEL") & prov_city == "NEW HAVEN"), loc(nums)
foreach num of loc nums {
	list year prov* xref if prov_num == "`num'", sepby(prov_num xref)
} 


exit


