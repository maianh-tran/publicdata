/*-------------------------------------------------------------drop_data.do
*/

qui do ~/Dropbox/publicdata/hcris_from_cms/control.do nodata

use ${output}/hcris_1996_2022.dta, clear

// drop 2022 data - seems weird 
drop if year==2022 

save ${output}/hcris_1996_2021.dta, replace

exit 




