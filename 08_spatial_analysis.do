
clear all 

set more off
set logtype text
set linesize 255 
set matsize 11000


cd 

* get current date
local date_str  = strtoname("`c(current_date)'  `c(current_time)'")
display "`date_str'"
cap log close
log using "..\Mobility\log\spatial_analysis_`date_str'.log", replace

*upload mobility data
use "..\Mobility\Data\prepared\mobility_new.dta", replace


*upload web index
merge m:1 ags5 using "..\Mobility\Data\raw\ags_prediction.dta"

drop if _merge!=3
drop _merge


*upload control variables
merge m:1 ags5 using "..\Mobility\Data\prepared\control_vars.dta"
drop if _merge!=3
drop _merge

*upload incidence rates
merge m:1 ags5 day using "..\Mobility\Data\prepared\infektionen_prepared_new.dta"

foreach vari in  kr_inf_rd kr_inz_rate{
	replace `vari'=0 if `vari'==.
}
 
drop _merge

* covid restrictions index
merge m:1 ags5 day using "..\Mobility\Data\prepared\restrictions.dta"

foreach vari in  kr_inz_rate kr_mn_idx_t{
	replace `vari'=0 if `vari'==. & day <=20200301
}
 
sort ags5 day
replace kr_mn_idx_t= kr_mn_idx_t[_n-1] if kr_mn_idx_t==. & day >=20221130
 
drop _merge

*upload broadband data
merge m:1 ags5 using "..\Mobility\Data\raw\mbits50.dta"

drop if _merge!=3
drop _merge


gen month = int(day/100)

/*
merge m:1 ags5 month using "C:\Users\JAX\Desktop\Mobility Analysis\conrol_vars\kurzarbeit.dta"


drop if _merge==2
drop _merge

*/

* bevölkerungsentwicklung
merge m:1 ags5 using "..\Mobility\Data\raw\bevölkerungsentwicklung.dta"

drop if _merge==2
drop _merge


*pendler
merge m:1 ags5 using "..\Mobility\Data\prepared\pendler.dta"


drop if _merge==2
drop _merge


merge m:1 ags5 using "..\Mobility\Data\prepared\network_providers.dta"

drop if _merge==2

drop _merge

gen mnot_every_provider =0
replace mnot_every_provider = 1 if not_every_provider==.

replace not_every_provider=0 if not_every_provider==. 
replace no_signal=0 if no_signal==. 


* Eisenach is not a Kreisfreie Stadt anymore
drop if ags5 == 16056
/*To do:
- sort control variables
**************************************************************************
*/


egen day_count = group(day)
gen week = int((day_count+1)/7)

*standardise digitalisation 
gen diff22_zero = WI_22_zero - WI_19_zero

foreach x in   WI_19 WI_22 diff22_zero WI_22_zero WI_19_zero diff_firm_level {
	egen `x's = std(`x')
	replace `x' = `x's
}

*prepare mobility vars
gen Mobility =(2*MobilityD + MobilityN)/3
la var Mobility "$\Delta$ mobility"
la var MobilityD "$\Delta$ mobility daytime"
la var MobilityN "$\Delta$ mobility nighttime"

/*
replace Mobility = . if Mobility>100
replace MobilityD = . if MobilityD>100
replace MobilityN = . if MobilityN>100

*/

*calculate weekdays and weekends
encode weekday, gen(weekday_help)
recode weekday_help 1=5 2=1 3=6 4=7 5=4 6=2 7=3, gen(weekday_int)  
labmask weekday_int, values(weekday)
gen weekend = 1 if weekday_int >5 & weekday_int!=. 
replace weekend = 0 if weekday_int <=5

*preprocess control variables

gen edu_hoch = (kr_beruf_hochschul + kr_beruf_prom)/(kr_ew_20 - kr_ew_00u03 -kr_ew_03u06 - kr_ew_06u10 - kr_ew_10u15)


gen non_workers = (kr_ew_00u03 +kr_ew_03u06 + kr_ew_06u10 + kr_ew_10u15 +kr_ew_65u75 +kr_ew_75)/kr_ew_20

gen service_sector=   kr_erwt_ao_b8/kr_erwt_ao 

gen share_men = kr_ew_m/kr_ew_20
la var share_men "% men"

replace ew_2019 = subinstr(ew_2019, "-", ".", .) 

*replace wrongly coded value
destring  ew_2019 ew_2020 ew_2021, replace
replace ew_2020 = (ew_2019+ew_2021)/2 if name=="Wartburgkreis"

gen change_pop=  ln(ew_2020)- ln(ew_2019) if day<=20210000
replace change_pop=  ln(ew_2021)- ln(ew_2019) if day>20210000


gen in_commuters =  ln(in_commuters_2020) - ln(in_commuters_2019) if day<=20210000
replace in_commuters =  ln(in_commuters_2021) - ln(in_commuters_2019) if day>20210000

gen out_commuters =  ln(out_commuters_2020) - ln(out_commuters_2019) if day<=20210000
replace out_commuters =  ln(out_commuters_2021) - ln(out_commuters_2019) if day>20210000



gen kr_typ =0 if Typ =="Kreis"
replace kr_typ =1 if Typ =="Kreisfreie Stadt"
replace kr_typ =0 if Typ =="Landkreis"
replace kr_typ =1 if Typ =="Stadtkreis"

encode bundesland, gen(land_int)
bys ags5: egen mbundesland = mean(land_int)
replace land_int = mbundesland  if land_int==.
replace kr_wo_kl= 0 if kr_wo_kl==2


replace kr_hh_eink_kl1  = kr_hh_eink_kl1/ (kr_ew_20/1000 )
replace kr_hh_1p  = kr_hh_1p/ (kr_ew_20/1000 )
replace kr_ew_20 = kr_ew_20/1000


la var WI_19 "digitalisation (Jan '20)"
la var WI_22 "digitalisation (Dec '22)"

la var WI_19_zero "digitalisation modified (Jan '20)"
la var WI_22_zero "digitalisation modified (Dec '22)"
la var diff22_zero "$\Delta$ digitalisation modified (Dec '22)"


*pandemic situation
la var kr_inz_rate "weekly cases"
la var kr_mn_idx_t "containment measures"

global pandemic "kr_inz_rate kr_mn_idx_t"

*socio-economic characteristics
la var edu_hoch "share of academics"
la var kr_bip_ew "GDP per inhabitant"
la var kr_hh_eink_kl1 "low-income households"
la var kr_sgb_qu "people on social benefits"

global socio_eco "edu_hoch kr_bip_ew  kr_hh_eink_kl1 kr_sgb_qu service_sector"

*infrastructure
la var kr_pkw_dichte "cars per 1,000 person"
la var mbits50 "$\geq$ 50 mbit/s"
la var no_signal "not covered"
la var not_every_provider "not covered by all"

global infrastructur "kr_pkw_dichte mbits50  not_every_provider no_signal  mnot_every_provider" 

*demographic characteristics
la var share_men "share of men"
la var non_workers "not of working age"
la var kr_ew_20 "number of inhabitants"
la var change_pop "change in population"
la var kr_ew_dichte "population density"
la var in_commuters "in-commuters"
la var out_commuters "out-commuters"
la var kr_hh_1p "one-person households"
la var kr_wfl "living space per household"

global demographics "share_men non_workers kr_ew_20 change_pop kr_ew_dichte out_commuters in_commuters kr_hh_1p  kr_wfl"

*geographic characteristics
la var kr_typ "city"
*la var kr_land "proportion in rural areas"
la var kr_wo_kl "West Germany"

global regional "kr_typ kr_wo_kl" 

*else
la var kr_ho_pot_ao "WfH potential"


gen phase = 0 if  day <20200322
replace phase = 1 if  day >=20200322
replace phase = 2 if  day >=20200504
replace phase = 3 if  day >=20201102
replace phase = 4 if  day >=20210701
replace phase = 5 if  day >=20211124
replace phase = 6 if  day >=20220320


label define phasename 	0 "$\times$ (0) pre-pandemic" ///
						1 "$\times$ (1) 1st lockdown" ///
						2 "$\times$ (2) 1st open period" ///
						3 "$\times$ (3) 2nd lockdown/ 1st WfH o." ///
						4 "$\times$ (4) 2nd open period" ///
						5 "$\times$ (5) 2nd WfH obligation" ///
						6 "$\times$ (6) post-pandemic" 
						
label value phase phasename

drop if Mobility ==. 


*save "C:\Users\JAX\Desktop\Mobility Analysis\merged_file.dta", replace

* Jena is a strong outlier especially if it cannot be weighted by the population size
drop if KR_NAME == "Jena"


xtset, clear
	cd "..\Mobility\Data\map"

est clear

	forvalues i=0(1)6 {
 
 	di `i'
	preserve

     keep if phase ==`i'

	 collapse (mean) Mobility WI_19 $pandemic $socio_eco  $infrastructur $demographics  $regional  land_int , by(ags5)
	
	* 2016 göttingen and harz where considered as two single districts, because it is not updated in the shape file. results are robust to whether we exclude göttingen or count it as douple (problem in change of ags codes over time)
	replace ags5 = 3156 if ags5 == 3159

	* drop eisenach as information about firm digitalisation is missing (problem in change of ags codes over time)
	drop if WI_19 == .
	merge m:1 ags5 using "C:\Users\JAX\Desktop\Mobility\Data\map\vg2500_ags5.dta"
	keep if _merge==3
	drop _merge	

	egen _ID = group(deid)
	spset _ID
	spset, modify shpfile(vg2500_krs_shp)
	reg Mobility c.WI_19 $pandemic $socio_eco $demographics  $infrastructur  $regional, robust
	spmatrix create contiguity W, normalize(row)  replace
	estat moran, errorlag(W)

	cap drop y_1 y_0 diff1
	
	eststo: spregress Mobility c.WI_19  $socio_eco  $pandemic  $infrastructur $demographics $regional  ,  ml dvarlag(W) ivarlag(W: c.WI_19  $infrastructur $demographics $regional  $pandemic  ) errorlag(W)
	  
			qui estadd local p_control "x", replace
			estadd local se_control "x", replace
			estadd local i_control "x", replace
			estadd local d_control "x", replace
			estadd local r_control "x", replace
			estadd scalar r2_p_est= e(r2_p)

	predict y_0
	replace WI_19 = WI_19 + 1 if ags5==08226 
	predict y_1 
	gen diff1 = y_1 - y_0
	gen period = `i' 
	keep ags5 period diff1 
	
	save "C:\Users\JAX\Desktop\Mobility Analysis\predicted_shock_`i'.dta", replace
	
	restore

}
	esttab  using "C:\Users\JAX\Desktop\Mobility\Tables\spatial.txt", replace drop( $socio_eco  $infrastructur $demographics  $pandemic  $regional ) tex s(p_control se_control i_control d_control r_control fd_control N ar2_est r2_p_est, label( "pandemic controls" "socio-economic controls" "infrastructure controls"  "demographic controls"   "geographic characteristics" "observations" "adjusted \(R^{2}\) " "pseudo \(R^{2}\) ")) t  addnotes ( "Clustered standard errors.") substitute(\_ _) label nogap  star(* 0.05 ** 0.01 *** 0.001) 

	log close
