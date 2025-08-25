cap prog drop examples
prog define examples
	args n_example 
	cap drop temp_sort
	gunique prov_num if temp_cond == 1
	qbys prov_num: gen temp_sort = runiformint(0,`r(unique)') if temp_cond == 1 & _n==1
	qbys prov_num (temp_sort): replace temp_sort = temp_sort[1]

	preserve 
		contract temp_sort 
		gsort temp_sort 
		loc t = temp_sort[`n_example']
	restore 

	gsort prov_num year fy_begin_dt
	if `n_example' != 0 {
		glevelsof prov_num if temp_sort <=`t' & !mi(temp_sort), loc(dups)
		foreach prov_num of loc dups {
			list prov_num year net_rev tot_rev tot_bed fy_*dt temp_cond  if prov_num == "`prov_num'", sepby(year) ab(32)
		}		
	}

	if `n_example' == 0 {
		glevelsof prov_num if temp_cond, loc(dups)
		foreach prov_num of loc dups {
			list prov_num year net_rev tot_rev tot_bed fy_*dt temp_cond if prov_num == "`prov_num'", sepby(year) ab(32)
		}		
	}
	
end
