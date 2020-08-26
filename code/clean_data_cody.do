/* Data Cleaning for Dr. Leslie
DV Incident Reports 

Cody Byers

Appropriate Accompanying Playlist: Classic Rock
*/


clear all
set more off

global raw_data I:incident_reports/raw_data/
global intermediate_data I:incident_reports/intermediate_data 
global clean_data I:incident_reports/clean_data



***LOUISVILLE CLEANUP***
use "$intermediate_data/tract_centroids2010", clear

// Keep the subset in counties where Louisville is located
keep if ctyfips == 21111

// t_ is a prefix to remind us that these are the tract centroid coordinates
rename latitude t_latitude
rename longitude t_longitude

// Save it as a tempfile (will disappear once code stops running)
tempfile tract_cent 
save `tract_cent'


import delimited "$intermediate_data\Louisville\louisville_geocodes.txt", clear 
rename x longitude
rename y latitude
keep address latitude longitude
save "$intermediate_data\Louisville\louisville_geocodes.dta", replace 



/*
import delimited "$raw_data\Louisville\Download20200807\Crime_Data_2019.csv", clear 


//Getting our addresses for ArcGIS - OPTIONAL. If not needed, comment this and the second import out
gen date1 = date(date_reported, "YMD#")
drop if year(date1) < 2019
keep block_address
duplicates drop
export delimited block_address using "I:\incident_reports\intermediate_data\Louisville\block_addresses.csv", replace
*/

import delimited "$raw_data\Louisville\Download20200807\Crime_Data_2019.csv", clear 

drop if city!="LOUISVILLE" // has a smattering of obs from a bunch of other cities?

//Generating incident date
gen incidentdate = date(date_reported, "YMD#")
format incidentdate %d

//Generating year variable
gen year = year(incidentdate)


//Generating month variable
gen month = month(incidentdate)

//Generating day variable
gen day = day(incidentdate)

//Generating week variable
gen week = week(incidentdate)


//Generating dv indicator
gen dv = regexm(uor_desc, "DOMESTIC") | regexm(uor_desc, "DOMESTIC VIOLENCE") | regexm(uor_desc, "DOMESTIC DISTURBANCE") | regexm(uor_desc, "FAMILY FIGHT")
gen totalincidents = 1

//Insert later: FIPS codes obtained from ArcGIS or geonear. 
replace city =  strtrim(city)
gen state = "KY"
replace city = "LOUISVILLE" if city == ""
replace city = upper(city)
replace state = "MO" if state == ""
replace block_address = strtrim(block_address)
gen address = regexr(block_address," BLOCK "," ")
replace address = address+" LOUISVILLE, KY"
merge m:1 address using "$intermediate_data/Louisville/louisville_geocodes.dta"
drop if _m == 2 //none
drop _m

// Use tract centroid information to lat/lon from incidents to Census tracts

// gen id = _n // raw data already have a unique id variable
// geoy is latitude (gives north/south coordinate), geox is longitude (gives east/west coordinate)
geonear id latitude longitude  using `tract_cent', neighbors( tractce t_latitude t_longitude) genstub(tractce) miles report(60)
replace tractce = . if mi_>50 //we don't want to include calls linked to census tracts that are over 50 miles away.
drop if tractce == . 
gen ctyfips = 21111

merge m:1 tractce ctyfips using "$intermediate_data/censustract_chars"
drop if incidentdate == .
collapse (sum) dv totalincidents, by(city ctyfips tractce incidentdate year month day)
drop if year < 2019
tsset tractce incidentdate
tsfill, full 
replace year = year(incidentdate)
replace month = month(incidentdate)
replace day = day(incidentdate)
replace dv = 0 if dv == .
replace city = "ST. LOUIS"
replace ctyfips = 29189
replace totalincidents = 0 if totalincidents == .

/*
//Collapsing to relevant variables, include census tract in the by() command, currently don't have it
collapse (sum) dv totalincidents, by(city incidentdate year month day)
*/

save "$clean_data\Louisville\cleaned_data.dta", replace






***LOS ANGELES CLEANUP***


// Read in data file with Census tract centroids for the whole country
//use ../intermediate_data/tract_centroids2010, clear
use "$intermediate_data/tract_centroids2010", clear

// Keep the subset in counties where Los Angeles is located
keep if ctyfips == 06037

// t_ is a prefix to remind us that these are the tract centroid coordinates
rename latitude t_latitude
rename longitude t_longitude

// Save it as a tempfile (will disappear once code stops running)
tempfile tract_cent 
save `tract_cent'



import delimited "$raw_data\Los Angeles\Download20200808\Crime_Data_from_2020_to_Present.csv", clear 



//Generating incident date
gen incidentdate = date(daterptd, "MDY#")
format incidentdate %d

//Generating year variable
gen year = year(incidentdate)


//Generating month variable
gen month = month(incidentdate)

//Generating day variable
gen day = day(incidentdate)


//Generating week variable
gen week = week(incidentdate)
gen city = "Los Angeles"
gen cityfips = 6037
//Generating dv indicator
gen dv = regexm(crmcddesc, "DOMESTIC") | regexm(crmcddesc, "DOMESTIC VIOLENCE") | regexm(crmcddesc, "DOMESTIC DISTURBANCE") | regexm(crmcddesc, "FAMILY FIGHT")
/* Data downloaded doesn't appear to have ANY domestic violence reports based on the above keywords. 
Thought it might be an error, but a search in Excel reveals zero incidents as well. Incorrect data? */

// Use tract centroid information to lat/lon from incidents to Census tracts
gen id2 = _n
// geoy is latitude (gives north/south coordinate), geox is longitude (gives east/west coordinate)
geonear id lat lon  using `tract_cent', neighbors( tractce t_latitude t_longitude) genstub(tractce) miles report(60)

collapse (sum) dv, by(cityfips city tractce incidentdate year month day)

save "$clean_data/Los Angeles/cleaned_data.dta", replace






***GAINESVILLE CLEANUP***


// Read in data file with Census tract centroids for the whole country
//use ../intermediate_data/tract_centroids2010, clear
use "$intermediate_data/tract_centroids2010", clear

// Keep the subset in counties where Gainesville is located
keep if ctyfips == 12001

// t_ is a prefix to remind us that these are the tract centroid coordinates
rename latitude t_latitude
rename longitude t_longitude

// Save it as a tempfile (will disappear once code stops running)
tempfile tract_cent 
save `tract_cent'



import delimited "$raw_data\Gainesville\Download20200808\Crime_Responses.csv", clear 



//Generating incidentdate
gen incidentdate = date(reportdate, "MDY#")
format incidentdate %d

//Generating year variable
gen year = year(incidentdate)


//Generating month variable
gen month = month(incidentdate)

//Generating day variable
gen day = day(incidentdate)

//Generating week variable
gen week = week(incidentdate)
//Generating dv indicator
replace incidenttype = upper(incidenttype)
gen dv = regexm(incidenttype, "DOMESTIC") | regexm(incidenttype, "DOMESTIC VIOLENCE") | regexm(incidenttype, "DOMESTIC DISTURBANCE") | regexm(incidenttype, "FAMILY FIGHT")
gen cityfips = 12001
// Use tract centroid information to lat/lon from incidents to Census tracts
gen id2 = _n
// geoy is latitude (gives north/south coordinate), geox is longitude (gives east/west coordinate)
geonear id latitude longitude  using `tract_cent', neighbors( tractce t_latitude t_longitude) genstub(tractce) miles report(60)

collapse (sum) dv, by(city cityfips tractce year month day incidentdate)

save "$clean_data\Gainesville\cleaned_data.dta", replace






***TUCSON CLEANUP***


/* import delimited "$raw_data\Tucson\Download20200808\Tucson_Police_Incidents_-_2020_-_Open_Data.csv", encoding(UTF-8) clear 
gen date1 = date(date_rept, "YMD#")
drop if year(date1) < 2019
keep address_public
duplicates drop
save address_public using "$intermediate_data\Tucson\address_public.dta", replace */

import delimited "$\intermediate_data\Tucson\tucson_geocodes.txt", clear 
rename x longitude
rename y latitude
keep address latitude longitude
save "$\intermediate_data\Tucson\tucson_geocodes.dta", replace 



import delimited "$raw_data\Tucson\Download20200808\Tucson_Police_Incidents_-_2020_-_Open_Data.csv", encoding(UTF-8) clear 
replace city =  strtrim(city)
replace state = strtrim(state)
replace zip = strtrim(zip)
replace city = "TUCSON" if city == ""
replace state = "AZ" if state == ""
gen address = address_public+" "+city+", "+state+" "+zip
replace address = regexr(address,"BLK OF ", "")
replace address = strtrim(address)
merge m:1 address using ../ui_intermediate_data/tucson_geocode
drop if _m == 2 //none
drop _m


//Generating incident date
gen incidentdate = date(date_rept, "YMD#")
format incidentdate %d

//Generating year variable
gen year = year(incidentdate)


//Generating month variable
gen month = month(incidentdate)

//Generating day variable
gen day = day(incidentdate)


//Generating week variable
gen week = week(incidentdate)

//Generating dv indicator
gen dv = regexm(statutdesc, "DOMESTIC") | regexm(statutdesc, "DOMESTIC VIOLENCE") | regexm(statutdesc, "DOMESTIC DISTURBANCE") | regexm(statutdesc, "FAMILY FIGHT")
gen totalincidents = 1

//Collapsing to relevant variables, include census tract in the by() command, currently don't have it.
//Can obtain census tract with ArcGIS 
collapse (sum) dv totalincidents, by(city cityfips incidentdate year month day)


save "$clean_data\Tucson\cleaned_data.dta", replace




***ST. LOUIS CLEANUP***

/* St. Louis had data in separate sheets for each month in 2020. The following code
cleans each individual sheet, then converts it into .dta form in order to be appended
to the January sheet, creating clean, combined data. It also combines all address
 data for use in ArcGIS in a similar manner.  */

local months January February March April May June July
quietly foreach month of local months{
	/*
    import delimited "$raw_data/St. Louis/Download20200811/`month'2020.csv", clear
	gen block_address = ileadsaddress + " " + ileadsstreet
	gen date1 = date(dateoccur, "MDY#")
	drop if year(date1) < 2019
	keep block_address
	duplicates drop
	sort block_address
	save "$intermediate_data/St. Louis/Block Addresses/Individual Months/`month'addresses.dta", replace */
	
	import delimited "$raw_data/St. Louis/Download20200811/`month'2020.csv", clear
    gen incidentdate = date(dateoccur, "MDY#")
    gen year = year(incidentdate)
    gen month = month(incidentdate)
    gen day = day(incidentdate)
	gen week = week(incidentdate)
	gen city = "St. Louis"
	gen totalincidents = 1
	gen dv = regexm(description, "DOMESTIC") | regexm(description, "DOMESTIC VIOLENCE") | regexm(description, "DOMESTIC DISTURBANCE") | regexm(description, "FAMILY FIGHT")

	//Add tract data when it becomes available from ArcGIS 
   sort incidentdate
   save "$intermediate_data/St. Louis/Individual Months/individ.`month'.dta", replace 
}



/*use "$intermediate_data/St. Louis/Block Addresses/Individual Months/Januaryaddresses.dta", clear
local months February March April May June July 
quietly foreach month of local months{
    append using "$intermediate_data/St. Louis/Block Addresses/Individual Months/`month'addresses.dta"
}
duplicates drop
save "$intermediate_data/St. Louis/Block Addresses/full_address_list.dta", replace 
*/

use "$intermediate_data/St. Louis/Individual Months/individ.January.dta", clear
local months February March April May June July 
quietly foreach month of local months{
    append using "$intermediate_data/St. Louis/Individual Months/individ.`month'.dta"
	
}
format incidentdate %d 
sort incidentdate 
gen totalincidents = 1
save "$intermediate_data/St. Louis/compiledmonths.dta", replace 

use "$intermediate_data/tract_centroids2010", clear

// Keep the subset in counties where St. Louis is located
keep if ctyfips == 29189

// t_ is a prefix to remind us that these are the tract centroid coordinates
rename latitude t_latitude
rename longitude t_longitude

// Save it as a tempfile (will disappear once code stops running)
tempfile tract_cent 
save `tract_cent'


import delimited "$intermediate_data\St. Louis\stlouis_geocodes.txt", clear 
rename x longitude
rename y latitude
keep address latitude longitude
save "$intermediate_data\St. Louis\stlouis_geocodes.dta", replace 

use "$intermediate_data/St. Louis/compiledmonths.dta", clear
replace city =  strtrim(city)
gen state = "MO"
replace city = "ST. LOUIS" if city == ""
replace city = upper(city)
replace state = "MO" if state == ""
gen address = ileadsaddress + " " + ileadsstreet +" "+city+", "+state+" "
replace address = regexr(address,"BLK OF ", "")
replace address = strtrim(address)
merge m:1 address using "$intermediate_data/St. Louis/stlouis_geocodes.dta"
drop if _m == 2 //none
drop _m

// Use tract centroid information to lat/lon from incidents to Census tracts
gen id = _n
// geoy is latitude (gives north/south coordinate), geox is longitude (gives east/west coordinate)
geonear id latitude longitude  using `tract_cent', neighbors( tractce t_latitude t_longitude) genstub(tractce) miles report(60)
replace tractce = . if mi_>50 //we don't want to include calls linked to census tracts that are over 50 miles away.
drop if tractce == . 
gen ctyfips = 29189

merge m:1 tractce ctyfips using "$intermediate_data/censustract_chars"
drop if incidentdate == .
collapse (sum) dv totalincidents, by(city ctyfips tractce incidentdate year month day)
drop if year < 2019
tsset tractce incidentdate
tsfill, full 
replace year = year(incidentdate)
replace month = month(incidentdate)
replace day = day(incidentdate)
replace dv = 0 if dv == .
replace city = "ST. LOUIS"
replace ctyfips = 29189
replace totalincidents = 0 if totalincidents == .
save "$clean_data/St. Louis/cleaned_data.dta", replace 

***NAPERVILLE CLEANUP***

// Read in data file with Census tract centroids for the whole country
//use ../intermediate_data/tract_centroids2010, clear
use "$intermediate_data/tract_centroids2010", clear

// Keep the subset in counties where Naperville is located
keep if ctyfips == 17043 | ctyfips==17197

// t_ is a prefix to remind us that these are the tract centroid coordinates
rename latitude t_latitude
rename longitude t_longitude

// Save it as a tempfile (will disappear once code stops running)
tempfile tract_cent 
save `tract_cent'





import delimited "$raw_data\Naperville\Download20200808\Police_Department_Incidents__2010_-_Current_Year_.csv", clear 

//import delimited "..\raw_data\Naperville\Download20200808\Police_Department_Incidents__2010_-_Current_Year_.csv", clear 


//Generating incident date
gen incidentdate = date(datereported, "MDY#")
format incidentdate %d

//Generating year variable
gen year = year(incidentdate)


//Generating month variable
gen month = month(incidentdate)

//Generating day variable
gen day = day(incidentdate)

//Generating week variable
gen week = week(incidentdate)
gen city = "Naperville"

// Use tract centroid information to lat/lon from incidents to Census tracts
gen id = _n
	// geoy is latitude (gives north/south coordinate), geox is longitude (gives east/west coordinate)
geonear id geoy geox  using `tract_cent', neighbors( tractce t_latitude t_longitude) genstub(tractce) miles report(60)


//Generating dv indicator
gen dv = regexm(reportedas, "DOMESTIC") | regexm(reportedas, "DOMESTIC VIOLENCE") | regexm(reportedas, "DOMESTIC DISTURBANCE") | regexm(reportedas, "FAMILY FIGHT")

//Collapsing to relevant variables. Include census tract in the by() command, currently don't have it.
//Can obtain census tract with ArcGIS or geonear
collapse (sum) dv, by(city tractce incidentdate year month day)


export delimited "$clean_data\Naperville\cleaned_data.csv", replace








***MESA CLEANUP***

// Read in data file with Census tract centroids for the whole country
//use ../intermediate_data/tract_centroids2010, clear
use "$intermediate_data/tract_centroids2010", clear

// Keep the subset in counties where Mesa is located
keep if ctyfips == 04013

// t_ is a prefix to remind us that these are the tract centroid coordinates
rename latitude t_latitude
rename longitude t_longitude

// Save it as a tempfile (will disappear once code stops running)
tempfile tract_cent 
save `tract_cent'


import delimited "$raw_data\Mesa\Download20200808\Police_Incidents.csv", clear 




//Generating incident date
gen incidentdate = date(reportdate, "MDY#")
format incidentdate %d

//Generating year variable
gen year = year(incidentdate)


//Generating month variable
gen month = month(incidentdate)

//Generating day variable
gen day = day(incidentdate)



//Generating week variable
gen week = week(incidentdate)
gen cityfips = 4013
//Generating dv indicator
gen dv = regexm(crimetype, "DOMESTIC") | regexm(crimetype, "DOMESTIC VIOLENCE") | regexm(crimetype, "DOMESTIC DISTURBANCE") | regexm(crimetype, "FAMILY FIGHT")


// Use tract centroid information to lat/lon from incidents to Census tracts
gen id = _n
// geoy is latitude (gives north/south coordinate), geox is longitude (gives east/west coordinate)
geonear id latitude longitude  using `tract_cent', neighbors( tractce t_latitude t_longitude) genstub(tractce) miles report(60)


//Collapsing to relevant variables. 
collapse (sum) dv, by(city cityfips tractce incidentdate year month day)


export delimited "$clean_data\Mesa\cleaned_data.csv", replace