/*--------------------------------------------------------------------control.do
*/

args nodata

// Flexibly allow for varying directory paths
cap cd ~/Dropbox/publicdata/pos_from_cms

// Project globals	
global rootdir  "`c(pwd)'"
global code		"${rootdir}/code" 
global raw 		"${rootdir}/rawdata"
global output 	"${rootdir}/output"
global temp 	"${rootdir}/temp"
global doc   	"${rootdir}/documentation"
	
// If running as pre-amble only:	
if "`nodata'"=="nodata" exit

/*
------------------------------------------

Process raw data 

------------------------------------------
*/
qui do ${code}/append_data.do 
qui do ${code}/process_data.do
qui do ${code}/restrict_data.do	// keep only hospitals in the U.S. 

/*
------------------------------------------

Geocode addresses

------------------------------------------
*/
qui do ${code}/prepare_geocoding_input.do
qui do ${code}/process_geocoding_output.do

/*
------------------------------------------

X-ref field 

------------------------------------------
*/
qui do ${code}/clean_xref.do

/*
------------------------------------------

Finalize

------------------------------------------
*/
qui do ${code}/finalize_data.do	// merge on lat/lon/etc
