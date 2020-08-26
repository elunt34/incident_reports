
/********************************
Prep Incident Data from Cities with Address but not Lat/Lon to map to local census tract

*********************************/

/****************
Louisville
****************/
insheet using ../intermediate_data/Louisville/block_addresses.csv, clear names

gen address = regexr(block_address," BLOCK "," ")
replace address = address+" LOUISVILLE, KY"

compress

export delimit ../intermediate_data/Louisville/louisville_address2geocode.csv, replace

/*****************
St. Louis
*****************/
use "../intermediate_data/St. Louis/Block Addresses/full_address_list.dta", clear

gen address = regexr(block_address,"\/","AND")
replace address = address+" ST. LOUIS, MO"

compress

export delimit "../intermediate_data/St. Louis/stlouis_address2geocode.csv", replace

/******************
Tucson - We already have addresses for the Calls, we will see if there are additional ones
******************/
insheet using ../intermediate_data/Tucson/address_public.csv, clear names

gen address = regexr(address_public," BLK OF "," ")
replace address = address+" TUCSON, AZ"

compress

export delimit "../intermediate_data/Tucson/tucson_address2geocode.csv", replace


