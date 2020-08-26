/*

Date Created: 8/7/2020
Coder: Eli Lunt

This do-file cleans raw data on 911 calls downloaded through the
police data initiative

Clean data should include the variables: year, day, month, incidentdate, week, dv, and tract_fips

*/

clear all
set more off

global raw_data I:/incident_reports/raw_data
global intermediate_data I:/incident_reports/intermediate_data
global clean_data I:/incident_reports/clean_data



***Chicago***

*read in census tract file
use "$intermediate_data/tract_centroids2010", clear
*only keep county code for cook county
keep if ctyfips == 17031
rename latitude t_latitude
rename longitude t_longitude
tempfile tract_cent 
save `tract_cent'

import delimited "$raw_data\Chicago\Download20200804\Crimes_-_2001_to_Present.csv", clear

*Generating incident date
gen year = substr(date,7,4)
gen day = substr(date,4,2)
gen month = substr(date,1,2)

destring year day month, replace

gen incidentdate = mdy(month,day,year)
	format incidentdate %d

gen week = week(incidentdate)

//Generating domestic violence indicator
gen dv = regexm(domestic,"true")
	
// Use tract centroid information to lat/lon from incidents to Census tracts
gen nid = _n

geonear nid latitude longitude  using `tract_cent', n( tractce t_latitude t_longitude) genstub(tractce) miles report(60)

* Drop last day in sample (sometimes only part of the day is included)
sort incidentdate
drop if _n==_N

*total incidents
gen totalincidents = 1

* collapse by day

collapse (sum) dv totalincidents, by(tractce year day month week incidentdate)

*fill in missing dates
tsset tractce incidentdate
tsfill, full

* data to fill in missing values. Probably can be cleaned up and shortened, but for now its here
replace year = year(incidentdate)
replace month = month(incidentdate)
replace day = day(incidentdate)
replace week = week(incidentdate)
replace dv = 0 if dv == .
replace totalincidents = 0 if totalincidents == .

save "$clean_data\Chicago\cleaned_data.dta", replace




*** Chandler ***

*read in census tract file
use "$intermediate_data/tract_centroids2010", clear
*only keep for Maricopa county
keep if ctyfips == 4013
rename latitude t_latitude
rename longitude t_longitude
tempfile tract_cent 
save `tract_cent' 

import delimited "$raw_data\Chandler\Download20200807\general_offenses.csv", clear

*Generating incident date
gen year = substr(reportmade,1,4)
gen day = substr(reportmade,9,2)
gen month = substr(reportmade,6,2)

destring year day month, replace

gen incidentdate = mdy(month,day,year)
	format incidentdate %d

gen week = week(incidentdate)

gen dv = regexm(summaryoffensedesc,"Dv")
	
// Use tract centroid information to lat/lon from incidents to Census tracts
gen nid = _n

geonear nid latitude longitude  using `tract_cent', n( tractce t_latitude t_longitude) genstub(tractce) miles report(60)


* Drop last day in sample (sometimes only part of the day is included)
sort incidentdate
drop if _n==_N

*total incidents
gen totalincidents = 1

* collapse by day

collapse (sum) dv totalincidents, by(tractce year day month week incidentdate)

*fill in missing dates
tsset tractce incidentdate
tsfill, full

* data to fill in missing values. Probably can be cleaned up and shortened, but for now its here
replace year = year(incidentdate)
replace month = month(incidentdate)
replace day = day(incidentdate)
replace week = week(incidentdate)
replace dv = 0 if dv == .
replace totalincidents = 0 if totalincidents == .

save "$clean_data\Chandler\cleaned_data.dta", replace

***Bremerton***

*for jANUARY because in .xls format ( almost identical to looped data below)
import excel "$raw_data/Bremerton/Download20200814/Jan2020_BPD.xls", firstrow clear
	gen year = substr(DATE,7,4)
	destring year, replace
	drop if year < 2019
	keep STREET
	duplicates drop
	sort STREET
	save "$intermediate_data/Bremerton/Block Addresses/Individual Months/Janaddresses.dta", replace
	import excel "$raw_data/Bremerton/Download20200814/Jan2020_BPD.xls", firstrow 		clear
	gen year = substr(DATE,7,4)
	gen day = substr(DATE,4,2)
	gen month = substr(DATE,1,2)
	destring year day month, replace
	gen incidentdate = mdy(month,day,year)
		format incidentdate %d
	gen week = week(incidentdate)
	gen dv = regexm(CHARGE,"DV") | regexm(CHARGE,"DOMESTIC VIOLENCE")
	sort incidentdate
	drop if _n==_N
	gen totalincidents = 1
	collapse (sum) dv totalincidents, by(year day month week incidentdate)
	save "$intermediate_data/Bremerton/Individual Months/individ.Jan.dta", replace 
	
*for other months in .xlsx format
local months Feb Mar Apr May Jun
quietly foreach month of local months{
    import excel "$raw_data/Bremerton/Download20200814/`month'2020_BPD.xlsx", firstrow 		clear
	gen year = substr(DATE,7,4)
	destring year, replace
	drop if year < 2019
	keep STREET
	duplicates drop
	sort STREET
	save "$intermediate_data/Bremerton/Block Addresses/Individual Months/`month'addresses.dta", replace 

	import excel "$raw_data/Bremerton/Download20200814/`month'2020_BPD.xlsx", firstrow 		clear

	*Generating incident date
	gen year = substr(DATE,7,4)
	gen day = substr(DATE,4,2)
	gen month = substr(DATE,1,2)

	destring year day month, replace

	gen incidentdate = mdy(month,day,year)
		format incidentdate %d

	gen week = week(incidentdate)

	gen dv = regexm(CHARGE,"DV") | regexm(CHARGE,"DOMESTIC VIOLENCE")


	* Drop last day in sample (sometimes only part of the day is included)
	sort incidentdate
	drop if _n==_N

	gen totalincidents = 1
	* collapse by day
	//Need to obtain census tract with ArcGis
	collapse (sum) dv totalincidents, by(year day month week incidentdate)

	save "$intermediate_data/Bremerton/Individual Months/individ.`month'.dta", replace
}

*Now append all the months into a single file
use "$intermediate_data/Bremerton/Block Addresses/Individual Months/Janaddresses.dta", clear
local months Feb March Apr May Jun 
quietly foreach month of local months{
    append using "$intermediate_data/Bremerton/Block Addresses/Individual Months/`month'addresses.dta"
}
duplicates drop
save "$intermediate_data/Bremerton/Block Addresses/full_address_list.dta", replace 


use "$intermediate_data/Bremerton/Individual Months/individ.Jan.dta", clear
local months Feb Mar Apr May Jun
quietly foreach month of local months{
    append using "$intermediate_data/Bremerton/Individual Months/individ.`month'.dta"
	
}
format incidentdate %d 
sort incidentdate 

save "$cleaned_data/Bremerton/cleaned_data.dta", replace 
***Cincinnati***

*read in census tract file
use "$intermediate_data/tract_centroids2010", clear
keep if ctyfips == 39061
rename latitude t_latitude
rename longitude t_longitude
tempfile tract_cent 
save `tract_cent' 

import delimited "$raw_data\Cincinnati\Download20200807\PDI__Police_Data_Initiative__Crime_Incidents.csv", clear

*Generating incident date
gen year = substr(date_reported,7,4)
gen day = substr(date_reported,4,2)
gen month = substr(date_reported,1,2)

destring year day month, replace

gen incidentdate = mdy(month,day,year)
	format incidentdate %d

gen week = week(incidentdate)

gen dv = regexm(offense,"DOMESTIC VIOLENCE")

// Use tract centroid information to lat/lon from incidents to Census tracts
gen nid = _n

geonear nid latitude longitude  using `tract_cent', n( tractce t_latitude t_longitude) genstub(tractce) miles report(60)

* Drop last day in sample (sometimes only part of the day is included)
sort incidentdate
drop if _n==_N

*total incidents
gen totalincidents = 1

* collapse by day

collapse (sum) dv totalincidents, by(tractce year day month week incidentdate)

*fill in missing dates
tsset tractce incidentdate
tsfill, full

* data to fill in missing values. Probably can be cleaned up and shortened, but for now its here
replace year = year(incidentdate)
replace month = month(incidentdate)
replace day = day(incidentdate)
replace week = week(incidentdate)
replace dv = 0 if dv == .
replace totalincidents = 0 if totalincidents == .

save "$clean_data\Cincinnati\cleaned_data.dta", replace

***Hartford***
/* does not have available dv data so code not complete

***Denver***

*read in census tract file
use "$intermediate_data/tract_centroids2010", clear
keep if ctyfips == 8031
rename latitude t_latitude
rename longitude t_longitude
tempfile tract_cent 
save `tract_cent'  

import delimited "$raw_data\Denver\Download20200807\crime.csv", clear

*Generating incident date
gen incidentdate = date(reported_date, "MDY#")
format incidentdate %d

gen year = year(incidentdate)
gen month = month(incidentdate)
gen day = day(incidentdate)
gen week = week(incidentdate)

//Generating dv indicator
gen dv = regexm(offense_type_id, "-dv")

// Use tract centroid information to lat/lon from incidents to Census tracts
gen nid = _n

geonear nid geo_lat geo_lon  using `tract_cent', n( tractce t_latitude t_longitude) genstub(tractce) miles report(60)

* Drop last day in sample (sometimes only part of the day is included)
sort incidentdate
drop if _n==_N

*total incidents
gen totalincidents = 1

* collapse by day

collapse (sum) dv totalincidents, by(tractce year day month week incidentdate)

*fill in missing dates
tsset tractce incidentdate
tsfill, full

* data to fill in missing values. Probably can be cleaned up and shortened, but for now its here
replace year = year(incidentdate)
replace month = month(incidentdate)
replace day = day(incidentdate)
replace week = week(incidentdate)
replace dv = 0 if dv == .
replace totalincidents = 0 if totalincidents == .

save "$clean_data\Denver\cleaned_data.dta", replace

***Austin***

*read in census tract file
use "$intermediate_data/tract_centroids2010", clear
keep if ctyfips == 48015
rename latitude t_latitude
rename longitude t_longitude
tempfile tract_cent 
save `tract_cent'  

import delimited "$raw_data\Austin\Download20200807\Crime_Reports.csv", clear

*Generating incident date
gen year = substr(occurreddate,7,4)
gen day = substr(occurreddate,4,2)
gen month = substr(occurreddate,1,2)

destring year day month, replace

gen incidentdate = mdy(month,day,year)
	format incidentdate %d

gen week = week(incidentdate)

//Generating dv indicator
gen dv = regexm(highestoffensedescription, "FAMILY DISTURBANCE") | regexm(highestoffensedescription, "DOMESTIC VIOLENCE") | regexm(familyviolence, "Y")

// Use tract centroid information to lat/lon from incidents to Census tracts
gen nid = _n

geonear nid latitude longitude  using `tract_cent', n( tractce t_latitude t_longitude) genstub(tractce) miles report(60)

* Drop last day in sample (sometimes only part of the day is included)
sort incidentdate
drop if _n==_N

*total incidents
gen totalincidents = 1

* collapse by day

collapse (sum) dv totalincidents, by(tractce year day month week incidentdate)

*fill in missing dates
tsset tractce incidentdate
tsfill, full

* data to fill in missing values. Probably can be cleaned up and shortened, but for now its here
replace year = year(incidentdate)
replace month = month(incidentdate)
replace day = day(incidentdate)
replace week = week(incidentdate)
replace dv = 0 if dv == .
replace totalincidents = 0 if totalincidents == .

save "$clean_data\Austin\cleaned_data.dta", replace
