
cd 

* get current date
local date_str  = strtoname("`c(current_date)'  `c(current_time)'")
display "`date_str'"
cap log close
log using "..\Mobility\log\firm_level_analysis_`date_str'.log", replace


use "..\Mobility\Data\raw\mip2021.dta", clear
rename lfdnr id
duplicates drop id, force
merge 1:1 id using "..\Mobility\Data\raw\corona_firm.dta"

drop id
keep if wzdig5 != .
keep if kreisnr != .


drop if exit_datum < 201800
drop if exit == 4
gen state = int(kreisnr/1000)


gen wzdig2 = int(wzdig5 /1000)
generate sectors = ""
replace sectors = "Agriculture, forestry and fishing (1-3)" if wzdig2 >= 1 & wzdig2 <= 3
replace sectors = "Mining and quarrying (5-9)" if wzdig2 >= 5 & wzdig2 <= 9
replace sectors = "Manufacturing industry (10-33)" if wzdig2 >= 10 & wzdig2 <= 33
replace sectors = "Energy supply (35)" if wzdig2 >= 35 & wzdig2 <= 35
replace sectors = "Water supply; sewage and waste disposal and pollution clean-up (36-39)" if wzdig2 >= 36 & wzdig2 <= 39
replace sectors = "Construction (41-43)" if wzdig2 >= 41 & wzdig2 <= 43
replace sectors = "Wholesale and retail trade; repair of motor vehicles (45-47)" if wzdig2 >= 45 & wzdig2 <= 47
replace sectors = "Transport and storage (49-53)" if wzdig2 >= 49 & wzdig2 <= 53
replace sectors = "Hospitality (56-56)" if wzdig2 >= 56 & wzdig2 <= 56
replace sectors = "Information and communication (58-63)" if wzdig2 >= 58 & wzdig2 <= 63
replace sectors = "Provision of financial and insurance services (64-66)" if wzdig2 >= 64 & wzdig2 <= 66
replace sectors = "Real estate and housing (68-68)" if wzdig2 >= 68 & wzdig2 <= 68
replace sectors = "Provision of professional, scientific and technical services (69-75)" if wzdig2 >= 69 & wzdig2 <= 75
replace sectors = "Provision of other economic services (77-82)" if wzdig2 >= 77 & wzdig2 <= 82
replace sectors = "Public administration, defense; social security (84-84)" if wzdig2 >= 84 & wzdig2 <= 84
replace sectors = "Education and teaching (85-85)" if wzdig2 >= 85 & wzdig2 <= 85
replace sectors = "Health and social services (86-88)" if wzdig2 >= 86 & wzdig2 <= 88
replace sectors = "Art, entertainment and recreation (90-93)" if wzdig2 >= 90 & wzdig2 <= 93
replace sectors = "Provision of other services (94-96)" if wzdig2 >= 94 & wzdig2 <= 96
replace sectors = "Private households with domestic staff; Undifferentiated goods- and services-producing activities of private households for own use (97-98)" if wzdig2 >= 97 & wzdig2 <= 98
replace sectors = "Extraterritorial organizations and entities (99-99)" if wzdig2 >= 99 & wzdig2 <= 99
encode sectors , gen(sectors_factors)

drop if sectors == ""

*e-commerce
drop if correaktion5 ==. | honorm ==. |holock1==.  |holock2==. 
la var WI_19 "digitalisation"

 foreach x in WI_19  {
	su `x'
	replace `x' = (`x' - r(mean)) / r(sd) 
}

*analysis of e-commerce


*generate a dummy for Ma�nahmen durch Corona: Ausweitung von digitalen Angeboten permanently 
replace correaktion5 =1 if correaktion5==2
la var correaktion5 "increase in digital business activities"


eststo clear
eststo: reg correaktion5 WI_19 i.sectors_factors  , robust

estadd local sectors "yes", replace
estadd local state "no", replace
qui estadd scalar r2_est= e(r2)
 
eststo: reg correaktion5 WI_19 i.sectors_factors i.state  , robust

estadd local sectors "yes", replace
estadd local state "yes", replace
qui estadd scalar r2_est= e(r2)

*Table S7: Link between firm digitalisation and increased e-commerce activity at the firm level.
esttab using "..\Mobility\Tables\e_commerce.txt",  drop(*.sectors_factors *.state) replace s(sectors state r2_est N, label("industry" "federal state" "R-squared" "observations")) t  addnotes( "Clustered standard errors.")   tex style(tex) label nogap 




** analysis of WfH share

* prepare for interval censored regression
eststo clear


gen rentlb1= 0  if honorm==1
    replace rentlb1= 1 if honorm==2
	replace rentlb1=10 if honorm==3
	replace rentlb1=26 if honorm==4
	replace rentlb1=51 if honorm==5
    replace rentlb1=76 if honorm==6
gen rentub1=0
	replace rentub1=10 if honorm==2
	replace rentub1=25 if honorm==3
	replace rentub1=50 if honorm==4
    replace rentub1=75 if honorm==5
    replace rentub1=100 if honorm==6

gen rentlb2= 0  if holock1==1 
    replace rentlb2=1 if  holock1==2
	replace rentlb2=11 if holock1==3
	replace rentlb2=26 if holock1==4
	replace rentlb2=51 if holock1==5
    replace rentlb2=76 if holock1==6
gen rentub2=0
	replace rentub2=10 if holock1==2
	replace rentub2=25 if holock1==3
	replace rentub2=50 if holock1==4
    replace rentub2=75 if holock1==5
    replace rentub2=100 if holock1==6
	
gen rentlb3= 0  if holock2==1 
    replace rentlb3=1 if  holock2==2
	replace rentlb3=11 if holock2==3
	replace rentlb3=26 if holock2==4
	replace rentlb3=51 if holock2==5
    replace rentlb3=76 if holock2==6
gen rentub3=0
	replace rentub3=10 if holock2==2
	replace rentub3=25 if holock2==3
	replace rentub3=50 if holock2==4
    replace rentub3=75 if holock2==5
    replace rentub3=100 if holock2==6
	
gen id = _n

*reshape for panel format
reshape long rentlb rentub, i(id) j(cc)

replace cc = cc-1



global DVARS "rentlb rentub"


la var rentlb "WfH share"

gen ld1 = 0 if cc ==0
replace ld1 = 1 if cc ==1
la var ld1 "1st lockdown"

gen ld2 = 0 if cc ==0
replace ld2 = 1 if cc ==2
la var ld2 "2nd lockdown"

gen WI_19ld1 = WI_19*ld1 
la var WI_19ld1 "digitalisation $\times$ 1st lockdown"

gen WI_19ld2 = WI_19*ld2 
la var WI_19ld2 "digitalisation $\times$ 2nd lockdown"


xtset id cc

est clear

eststo: intreg $DVARS WI_19 ld1 WI_19ld1 i.sectors_factors if cc!=2 , cluster(id)

estadd local sectors "yes", replace
estadd local state "no", replace
estadd scalar ar2_est= e(ll)  


eststo: intreg $DVARS  ld1 WI_19ld1  i.sectors_factors i.state WI_19 if cc!=2   , cluster(id)

estadd local sectors "yes", replace
estadd local state "yes", replace
estadd scalar ar2_est= e(ll)  


eststo: intreg $DVARS WI_19 ld2 WI_19ld2  i.sectors_factors  if cc!=1 , cluster(id)

estadd local sectors "yes", replace
estadd local state "no", replace
estadd scalar ar2_est= e(ll)


eststo: intreg $DVARS WI_19 ld2 WI_19ld2 i.sectors_factors   i.state  if cc!=1 , cluster(id)

estadd local sectors "yes", replace
estadd local state "yes", replace
estadd scalar ar2_est= e(ll)  
 
*Table S6: Link between firm digitalisation and WfH at the firm level.
esttab using"..\Mobility\Tables\firm_WFH.txt",     drop(*.sectors_factors *.state) order(WI_19 ld1 ld2 WI_19ld1   WI_19ld2) replace s(sectors state ar2_est N, label("industry" "federal state" "log-liklihood" "observations")) t  addnotes( "Clustered standard errors.")   tex style(tex) label nogap 

log close