/*

Date Created: 8/13/2020
Coder: Emily Leslie

This do-file cleans raw data on police incident reports.

v1: Starts with data cleaned in clean_data_eli.do and clean_data_cody.do (all cleaning
	code will be brought together here in future versions if the project moves forward).
	Used geocoding in ArcGIS to include Louisville, St. Louis, Tucson.

Notes for RAs:
- Try to avoid spaces in folder and file names (see section that appends all cities for an example of why)
	- More generally, keep looping convenience in mind (not Provo then provo)
- Also need to add county fips codes
	- Especially important for Naperville
- Remind myself why we stopped with Mesa? (only has 2019 data right now)
- Why is dv = 0 for all LA obs?
- Why so few tracts in Austin?  Missing lat/lon?
- De-prioritizing for now, but let's get the code (v2) organized so it would be easy to come back to with
updated data/additional cities
*/

clear all
set more off

*** GLOBALS ***

/*
* RA globals
global raw_data I:/incident_reports/raw_data
global intermediate_data I:/incident_reports/intermediate_data
global clean_data I:/incident_reports/clean_data

*/

* Emily globals
global raw_data ../raw_data
global intermediate_data ../intermediate_data
global clean_data ../clean_data



*** PREP TRACT UNEMPLOYMENT ESTIMATES ***
insheet using $raw_data/censustract_unemployment_predictions.csv, clear
rename fips tractfips
format tractfips %12.0f
foreach t in 2 3 4 5 6 {
	rename unemploymentrate_2020_0`t' urate_mo`t'
}
gen d_urate_febjune = urate_mo6-urate_mo2
gen pctd_urate_febjune = ((urate_mo6-urate_mo2)/urate_mo2)*100

gen ctyfips = floor(tractfips/1000000)
gen tractce = tractfips- (ctyfips*1000000)

compress
save $intermediate_data/censustract_chars, replace



*** CITY-BY-CITY CLEANING ***
// For now, contained in clean_data_eli.do and clean_data_cody.do-file


*** COMBINE TRACT/DAY DATA ACROSS CITIES ***
// Leaving off Naperville because of two counties
// Mesa only has 2019 data
// LA doesn't seem to have dv identified in 2020
// Tucson: need to recreate tract identification code in clean_data_cody.do



* Append data for all cities together
clear
foreach c in Chicago Austin Chandler Cincinnati Denver Gainesville Louisville	{
    
	append using $clean_data/`c'/cleaned_data
	
}

append using "$clean_data/St. Louis/cleaned_data"

replace city = lower(city)


* Restrict to 2019-2020 for simplicity
keep if year>=2019

* Trim so last dates line up (so we have a balanced panel)
// Chicago's is earliest (27jun2020)
bys city: egen temp = max(incidentdate)
format temp %td
egen temp2 = min(temp)
drop if incidentdate>temp2
drop temp*

* Drop if missing tract
drop if tractce==.

* Gen dow
gen dow = dow(incidentdate)

* Fill in week (not constructed in all cities)
replace week = week(incidentdate) if week==.

* Fill in county fips codes (not all preserved in clean_data_eli.do and clean_data_cody.do)
drop ctyfips
gen ctyfips = .
// Move code up to individual city cleaning data
replace ctyfips = 12001 if city=="gainesville"
replace ctyfips = 17031 if city=="chicago"
replace ctyfips = 48015 if city=="austin"
replace ctyfips = 4013 if city=="chandler"
replace ctyfips = 39061 if city=="cincinnati"
replace ctyfips = 8031 if city=="denver"
replace ctyfips = 21111 if city=="louisville"
replace ctyfips = 29189 if city=="st. louis"

merge m:1 ctyfips tractce using $intermediate_data/censustract_chars
	keep if _m==3	// 5,908 out of 1.3+ million not matched from master
	drop _m
	
	
* Create groups by predicted tract unemployment rate
// using predictions for June for now (all highly correlated)
xtile d_urate_quartile = d_urate_febjune, nq(4)

gen hi_urate = d_urate_quartile>=3 // above median
gen lo_urate = d_urate_quartile<=2 // below median

xtile urate06_quartile = urate_mo6, nq(4)


* Week dummies + interactions
forval w = 1/52	{
	
	gen week`w' = week==`w'
	gen week`w'xhi = week`w'*hi_urate
	gen week`w'xd_urate = week`w'*d_urate_febjune
	gen week`w'xurate06 = week`w'*urate_mo6
	
}

* Numeric city ID
egen cityid = group(city)

* Dummy for any DV
gen dv_dummy = dv>0

save $clean_data/tracts_byday_appended, replace


*** Make hi/lo unemployment data at week level (for figure)
use $clean_data/tracts_byday_appended, clear

drop if city=="losangeles"

keep hi_urate lo_urate dv* totalincidents week year

collapse (mean) dv* totalincidents, by(hi_urate lo_urate week year)

save $clean_data/hilo_urate_byweek, replace


*** Make quartile unemployment data at week level (for figure)
use $clean_data/tracts_byday_appended, clear

keep d_urate_quartile dv* totalincidents week year

collapse (mean) dv* totalincidents, by(d_urate_quartile week year)

save $clean_data/quart_urate_byweek, replace







****************************
*** PRELIMINARY ANALYSIS ***
****************************
// April ends in week 18 (4/29-5/5)
// George Floyd protests began on May 26 (last day of week 21)

* Compare above/below median for 2020
use $clean_data/hilo_urate_byweek, clear

line dv_dummy week if hi & year==2020 & week>=3, lcolor(black) lpattern(solid) || ///
	line dv_dummy week if lo & year==2020 & week>=3, lcolor(black) lpattern(dash)
	
line dv_dummy week if hi & year==2020 & week>=3, lcolor(black) lpattern(solid) || ///
	line dv_dummy week if hi & year==2019 & week>=3, lcolor(black) lpattern(dash)

* By quartile for 2020
use $clean_data/quart_urate_byweek, clear

line dv_dummy week if d_urate_quartile==4 & year==2020 & week>=3, lcolor(black) lpattern(solid) || ///
	line dv_dummy week if d_urate_quartile==3 & year==2020 & week>=3, lcolor(black) lpattern(dash) || ///
	line dv_dummy week if d_urate_quartile==2 & year==2020 & week>=3, lcolor(red) lpattern(solid) || ///
	line dv_dummy week if d_urate_quartile==1 & year==2020 & week>=3, lcolor(red) lpattern(dash)
	
line dv_dummy week if d_urate_quartile==4 & year==2019 & week>=3, lcolor(black) lpattern(solid) || ///
	line dv_dummy week if d_urate_quartile==3 & year==2019 & week>=3, lcolor(black) lpattern(dash) || ///
	line dv_dummy week if d_urate_quartile==2 & year==2019 & week>=3, lcolor(red) lpattern(solid) || ///
	line dv_dummy week if d_urate_quartile==1 & year==2019 & week>=3, lcolor(red) lpattern(dash)

line totalincidents week if d_urate_quartile==4 & year==2020 & week>=3, lcolor(black) lpattern(solid) || ///
	line totalincidents week if d_urate_quartile==3 & year==2020 & week>=3, lcolor(black) lpattern(dash) || ///
	line totalincidents week if d_urate_quartile==2 & year==2020 & week>=3, lcolor(red) lpattern(solid) || ///
	line totalincidents week if d_urate_quartile==1 & year==2020 & week>=3, lcolor(red) lpattern(dash)

	
	
* hi vs. lo
use $clean_data/tracts_byday_appended, clear

areg dv_dummy week2xhi week3xhi week4xhi week5xhi week6xhi week7xhi week8xhi ///
	week9xhi week10xhi week11xhi week12xhi week13xhi week14xhi week15xhi week16xhi ///
	week17xhi week18xhi week19xhi week20xhi week21xhi week22xhi week23xhi ///
	week24xhi week25xhi week26xhi week28xhi week29xhi ///
	i.cityid##i.week i.cityid##i.dow if year==2020 & week>1 & city!="austin", a(tractce) vce(cluster tractce)
	
coefplot, keep(week*) vertical omit ///
	rename(week1xhi = "1" week2xhi = "2" week3xhi = "3" week4xhi = "4" week5xhi = "5" ///
	week6xhi = "6" week7xhi = "7" week8xhi = "8" week9xhi = "9" week10xhi = "10" week11xhi = "11" ///
	week12xhi = "12" week13xhi = "13" week14xhi = "14" week15xhi = "15" week16xhi = "16" ///
	week17xhi = "17" week18xhi = "18" week19xhi = "19" week20xhi = "20" week21xhi = "21" ///
	week22xhi = "22" week23xhi = "23" week24xhi = "24" week25xhi = "25" week26xhi = "26" ///
	week27xhi = "27" week28xhi = "28" week29xhi = "29") 

	
	
* using continuous measure of change in unemployment rate
use $clean_data/tracts_byday_appended, clear

areg dv_dummy week2xd_urate week3xd_urate week4xd_urate week5xd_urate week6xd_urate week7xd_urate week8xd_urate ///
	week9xd_urate week10xd_urate week11xd_urate week12xd_urate week13xd_urate week14xd_urate week15xd_urate week16xd_urate ///
	week17xd_urate week18xd_urate week19xd_urate week20xd_urate week21xd_urate week22xd_urate week23xd_urate ///
	week24xd_urate week25xd_urate week26xd_urate week28xd_urate week29xd_urate ///
	i.cityid##i.week i.cityid##i.dow if year==2020 & week>1 & city!="austin" & city!="chicago", a(tractce) vce(cluster tractce)
	
coefplot, keep(week*) vertical omit ///
	rename(week2xd_urate = "2" week3xd_urate = "3" week4xd_urate = "4" week5xd_urate = "5" ///
	week6xd_urate = "6" week7xd_urate = "7" week8xd_urate = "8" week9xd_urate = "9" week10xd_urate = "10" week11xd_urate = "11" ///
	week12xd_urate = "12" week13xd_urate = "13" week14xd_urate = "14" week15xd_urate = "15" week16xd_urate = "16" ///
	week17xd_urate = "17" week18xd_urate = "18" week19xd_urate = "19" week20xd_urate = "20" week21xd_urate = "21" ///
	week22xd_urate = "22" week23xd_urate = "23" week24xd_urate = "24" week25xd_urate = "25" week26xd_urate = "26" ///
	week27xd_urate = "27" week28xd_urate = "28" week29xd_urate = "29") 
 
 
 
 
