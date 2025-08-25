/*--------------------------------------------------------------------control.do
*/

args nodata

// Flexibly allow for varying directory paths
cap cd ~/Dropbox/publicdata/hcris_from_cms

// Project globals	
global rootdir  "`c(pwd)'"
global code		"${rootdir}/code" 
global raw 		"${rootdir}/rawdata"
global output 	"${rootdir}/output"
global temp 	"${rootdir}/temp"
global doc   	"${rootdir}/documentation"

foreach folder in "${code}" "${rawdata}"  "${output}" "${temp}" "${doc}" {
	cap mkdir `folder'
}

qui do ${code}/prog_examples.do

// If running as pre-amble only:	
if "`nodata'"=="nodata" exit

// why is 2022 so sparse? 

/*
------------------------------------------

Process data from NBER

------------------------------------------
*/
qui do ${code}/unzip_data.do
qui do ${code}/process_data.do

/*
------------------------------------------

Grab bed and revenue

------------------------------------------
*/
qui do ${code}/grab_needed_numeric_data.do

/*
------------------------------------------

Grab report data

------------------------------------------
*/
qui do ${code}/clean_report_data.do

/*
------------------------------------------

Bring together

------------------------------------------
*/
qui do ${code}/bring_together.do	// drop 2022 here - seems weird 
qui do ${code}/create_flag.do

/*
------------------------------------------

Deduplicate

------------------------------------------
*/
qui do ${code}/deduplicate.do
qui do ${code}/drop_data.do // drop 2022 data - seems weird 

/*
------------------------------------------

Old code to be removed: prorate based on number of days

------------------------------------------
*/
qui do ${code}/create_fy_cy.do

