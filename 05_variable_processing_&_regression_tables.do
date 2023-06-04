
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
log using "..\Mobility\log\variable_processing_&_regression_analysis_`date_str'.log", replace


*upload mobility data
use "..\Mobility\Data\prepared\mobility_new.dta", replace


*upload web index
* additional observation in ags_prediction has no identifier
merge m:1 ags5 using "..\Mobility\Data\raw\ags_prediction_dp.dta"

drop if _merge!=3
drop _merge


*upload control variables
merge m:1 ags5 using "..\Mobility\Data\prepared\control_vars.dta"
drop if _merge!=3
drop _merge

*upload incidence rates
merge m:1 ags5 day using "..\Mobility\Data\prepared\infektionen_prepared_new.dta"

*set incidence rate to zero if missing before March 2020
replace kr_inz_rate=0 if kr_inz_rate==. &  day <20200301
 
drop if _merge==2 
drop _merge

* covid restrictions index
merge m:1 ags5 day using "..\Mobility\Data\prepared\restrictions.dta"

*set index to zero if missing before March 2020 (meaning: no covid restrictions have been in place)
replace kr_mn_idx_t=0 if kr_mn_idx_t==. & day <=20200301

*impute index for the end of the observed time frame (use the last observed value)
sort ags5 day
replace kr_mn_idx_t= kr_mn_idx_t[_n-1] if kr_mn_idx_t==. & day >=20221130

drop if _merge==2 
drop _merge

*upload broadband data
merge m:1 ags5 using "..\Mobility\Data\raw\mbits50.dta"

drop if _merge!=3
drop _merge


* changes in the population
merge m:1 ags5 using "..\Mobility\Data\raw\bevölkerungsentwicklung.dta"

drop if _merge==2
drop _merge


*commuters
merge m:1 ags5 using "..\Mobility\Data\prepared\pendler.dta"

drop if _merge==2
drop _merge

*area not covered by network providers
merge m:1 ags5 using "..\Mobility\Data\prepared\network_providers.dta"

drop if _merge==2
drop _merge

*control for missing districts
gen missing_info_provider =0
replace missing_info_provider = 1 if not_every_provider==.
replace not_every_provider=0 if missing_info_provider==1
replace no_signal=0 if missing_info_provider==1


*******************************************
* preprocessing
*******************************************


*generate time vars
egen day_count = group(day)
gen week = int((day_count+1)/7)
gen month = int(day/100)

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

*calculate weekdays and weekends
encode weekday, gen(weekday_help)
recode weekday_help 1=5 2=1 3=6 4=7 5=4 6=2 7=3, gen(weekday_int)  
labmask weekday_int, values(weekday)
gen weekend = 1 if weekday_int >5 & weekday_int!=. 
replace weekend = 0 if weekday_int <=5


*standardise digitalisation 
gen diff22_zero = WI_22_zero - WI_19_zero

foreach x in   WI_19 WI_22 diff22_zero WI_22_zero WI_19_zero diff_firm_level {
	egen `x's = std(`x')
	replace `x' = `x's
}

*prepare mobility vars
*daytime mobility
gen Mobility =(2*MobilityD + MobilityN)/3
la var Mobility "$\Delta$ mobility"
la var MobilityD "$\Delta$ mobility daytime"
la var MobilityN "$\Delta$ mobility nighttime"


*process control variables

*share of academics
gen edu_hoch = (kr_beruf_hochschul + kr_beruf_prom)/(kr_ew_20 - kr_ew_00u03 -kr_ew_03u06 - kr_ew_06u10 - kr_ew_10u15)

*share of workers in service sector
gen service_sector=   kr_erwt_ao_b8/kr_erwt_ao 

*non workers
gen non_workers = (kr_ew_00u03 +kr_ew_03u06 + kr_ew_06u10 + kr_ew_10u15 +kr_ew_65u75 +kr_ew_75)/kr_ew_20

*share of men
gen share_men = kr_ew_m/kr_ew_20
la var share_men "% men"


*calculate change in population
replace ew_2019 = subinstr(ew_2019, "-", ".", .) 

destring  ew_2019 ew_2020 ew_2021, replace
*replace wrong value by average
replace ew_2020 = (ew_2019+ew_2021)/2 if name=="Wartburgkreis"

gen change_pop=  ln(ew_2020)- ln(ew_2019) if day<=20210000
replace change_pop=  ln(ew_2021)- ln(ew_2019) if day>20210000

*change commuters
gen in_commuters =  ln(in_commuters_2020) - ln(in_commuters_2019) if day<=20210000
replace in_commuters =  ln(in_commuters_2021) - ln(in_commuters_2019) if day>20210000

gen out_commuters =  ln(out_commuters_2020) - ln(out_commuters_2019) if day<=20210000
replace out_commuters =  ln(out_commuters_2021) - ln(out_commuters_2019) if day>20210000


*regional characteristics
gen kr_typ =0 if Typ =="Kreis"
replace kr_typ =1 if Typ =="Kreisfreie Stadt"
replace kr_typ =0 if Typ =="Landkreis"
replace kr_typ =1 if Typ =="Stadtkreis"

encode bundesland, gen(land_int)
bys ags5: egen mbundesland = mean(land_int)
replace land_int = mbundesland  if land_int==.
replace kr_wo_kl= 0 if kr_wo_kl==2

*adjust values by population size 
replace kr_hh_eink_kl1  = kr_hh_eink_kl1/ (kr_ew_20/1000 )
replace kr_hh_1p  = kr_hh_1p/ (kr_ew_20/1000 )
replace kr_ew_20 = kr_ew_20/1000


*generate labels and globals
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
la var service_sector "share of workers in the service sector"
global socio_eco "edu_hoch kr_bip_ew  kr_hh_eink_kl1 kr_sgb_qu service_sector"

*infrastructure
la var kr_pkw_dichte "cars per 1,000 person"
la var mbits50 "$\geq$ 50 mbit/s"
la var no_signal "not covered"
la var not_every_provider "not covered by all"

global infrastructur "kr_pkw_dichte mbits50  not_every_provider no_signal  missing_info_provider" 

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

drop if Mobility ==. 

save "..\Mobility\Data\merged_file.dta", replace

xtset ags5 day_count

*average effect with respect to daytime and nighttime 

pwcorr WI_19 WI_22


*******************************************
* Descriptive Statistics
*******************************************


*Table A.4: Overview of descriptive statistics.
est clear
estpost summarize Mobility MobilityD MobilityN WI_19 WI_22 WI_19_zero WI_22_zero diff22_zero $pandemic $socio_eco $infrastructur $demographics $regional  if Mobility !=.& kr_inz_rate!=. & day >=20200101 , d 
esttab, tex cells(sum_w(fmt(2)) mean(fmt(2)) sd p10(fmt(2)) p90(fmt(2)) ) nomtitle nonumber label  



*******************************************
* Econometric Analysis
*******************************************

** main table **

xtset ags5 day_count

foreach x in  WI_19 WI_22 {

est clear

	*no control variables
	eststo: xtreg Mobility io1.phase##c.`x' i.month   [aw=kr_ew_20]  , fe cluster(ags5)

	qui estadd local time "x", replace
	qui estadd local p_control " ", replace
	qui estadd local se_control " ", replace
	qui estadd local i_control " ", replace
	qui estadd local d_control " ", replace
	qui estadd local r_control " ", replace
	qui estadd scalar r2_est= e(r2)

	test 1.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff1=r(p)
	test 2.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff2=r(p)
	test 3.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff3=r(p)
	test 4.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff4=r(p)
	test 5.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff5=r(p) 

	*pandemic situation
	eststo: xtreg Mobility io1.phase##c.`x' io1.phase#c.($pandemic) i.month   [aw=kr_ew_20] , fe cluster(ags5)

	qui estadd local time "x", replace
	qui estadd local p_control "x", replace
	qui estadd local se_control "", replace
	qui estadd local i_control "", replace
	qui estadd local d_control "", replace
	qui estadd local r_control "", replace
	qui estadd scalar r2_est= e(r2)
	 
	test 1.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff1=r(p)
	test 2.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff2=r(p)
	test 3.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff3=r(p)
	test 4.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff4=r(p)
	test 5.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff5=r(p) 


	*socio economic
	eststo: xtreg Mobility io1.phase##c.`x' io1.phase#c.($socio_eco) i.month   [aw=kr_ew_20] , fe cluster(ags5)
	 
	qui estadd local time "x", replace
	qui estadd local p_control "", replace
	qui estadd local se_control "x", replace
	qui estadd local i_control "", replace
	qui estadd local d_control "", replace
	qui estadd local r_control "", replace
	qui estadd scalar r2_est= e(r2)
	 
	test 1.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff1=r(p)
	test 2.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff2=r(p)
	test 3.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff3=r(p)
	test 4.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff4=r(p)
	test 5.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff5=r(p) 


	*infrastructur
	eststo:  xtreg Mobility io1.phase##c.`x' io1.phase#c.($infrastructur) i.month   [aw=kr_ew_20] , fe cluster(ags5) 

	qui estadd local time "x", replace
	qui estadd local p_control "", replace
	qui estadd local se_control "", replace
	qui estadd local i_control "x", replace
	qui estadd local d_control "", replace
	qui estadd local r_control "", replace
	qui estadd scalar r2_est= e(r2)
	 
	test 1.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff1=r(p)
	test 2.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff2=r(p)
	test 3.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff3=r(p)
	test 4.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff4=r(p)
	test 5.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff5=r(p) 

	*demographics
	eststo: xtreg Mobility io1.phase##c.`x' io1.phase#c.($demographics) i.month   [aw=kr_ew_20] , fe cluster(ags5) 

	qui estadd local time "x", replace
	qui estadd local p_control "", replace
	qui estadd local se_control "", replace
	qui estadd local i_control "", replace
	qui estadd local d_control "x", replace
	qui estadd local r_control "", replace
	qui estadd scalar r2_est= e(r2)

	test 1.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff1=r(p)
	test 2.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff2=r(p)
	test 3.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff3=r(p)
	test 4.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff4=r(p)
	test 5.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff5=r(p) 


	*regional
	eststo: xtreg Mobility io1.phase##c.`x' io1.phase#c.($regional) i.month   [aw=kr_ew_20] , fe cluster(ags5) 

	qui estadd local time "x"
	qui estadd local p_control "", replace
	qui estadd local se_control "", replace
	qui estadd local i_control "", replace
	qui estadd local d_control "", replace
	qui estadd local r_control "x", replace
	qui estadd scalar r2_est= e(r2)
	 
	test 1.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff1=r(p)
	test 2.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff2=r(p)
	test 3.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff3=r(p)
	test 4.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff4=r(p)
	test 5.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff5=r(p) 

	*all control variables

	eststo: xtreg Mobility io1.phase##c.`x' io1.phase#c.($pandemic ) io1.phase#c.($socio_eco) io1.phase#c.($infrastructur) io1.phase#c.($demographics) io1.phase#c.($regional)  i.month    [aw=kr_ew_20] , fe cluster(ags5) 

	 qui estadd local time "x", replace
	 qui estadd local p_control "x", replace
	 qui estadd local se_control "x", replace
	 qui estadd local i_control "x", replace
	 qui estadd local d_control "x", replace
	 qui estadd local r_control "x", replace
	 qui estadd scalar r2_est= e(r2)
	 
	 
	test 1.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff1=r(p)
	test 2.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff2=r(p)
	test 3.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff3=r(p)
	test 4.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff4=r(p)
	test 5.phase#c.`x' = 6.phase#c.`x'
	qui estadd scalar diff5=r(p) 

* Table 1: DiD results providing insights into changes in the link between mobility reductions and firm digitalisation for different phases of the pandemic.

*Table S4: DiD results providing insights into changes in the link between mobility reductions and firm digitalisation with respect to different phases of the pandemic using digitalisation observed in 2022.
 
esttab using "..\Mobility\Tables\_`x'_time.txt", keep(*.phase#c.`x') tex s(time p_control se_control i_control d_control r_control N r2_est diff1 diff2 diff3 diff4 diff5, label("year-month fixed effects" "pandemic controls"  "socioeconomic controls" "infrastructure controls"  "demographic controls"   "geographic controls" "observations" "\(R^{2}\)" "\hline \\ $\beta^1 \neq \beta^6$" "$\beta^2 \neq \beta^6$" "$\beta^3 \neq \beta^6$" "$\beta^4 \neq \beta^6$" "$\beta^5 \neq \beta^6$") fmt(%9.2f)) t  addnotes ( "Clustered standard errors.") substitute(\_ _) label nogap replace  star(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

}


** average effect **

foreach x in WI_19  {

est clear

eststo: reg Mobility `x'  $pandemic $socio_eco $infrastructur $demographics $regional  i.month [aw=kr_ew_20] if phase != 0 & phase !=6 , cluster(ags5) 

 qui estadd local time "x", replace
  qui estadd local p_control "x", replace
 qui estadd local se_control "x ", replace
 qui estadd local i_control "x ", replace
 qui estadd local d_control "x ", replace
 qui estadd local r_control " x", replace
 qui estadd scalar r2_est= e(r2)

 
eststo: reg MobilityD `x' $pandemic $socio_eco $infrastructur $demographics $regional  i.month [aw=kr_ew_20] if phase != 0 & phase !=6 , cluster(ags5) 

 qui estadd local time "x", replace
 qui estadd local p_control "x", replace
 qui estadd local se_control "x", replace
 qui estadd local i_control "x", replace
 qui estadd local d_control "x", replace
 qui estadd local r_control "x", replace
 qui estadd scalar r2_est= e(r2)

eststo: reg MobilityN `x' $pandemic  $socio_eco $infrastructur $demographics $regional  i.month [aw=kr_ew_20] if phase != 0 & phase !=6 ,  cluster(ags5) 

 qui estadd local time "x", replace
 qui estadd local p_control "x", replace
 qui estadd local se_control "x", replace
 qui estadd local i_control "x", replace
 qui estadd local d_control "x", replace
 qui estadd local r_control "x", replace
 qui estadd scalar r2_est= e(r2)

eststo: reg MobilityD `x' $pandemic   $socio_eco $infrastructur $demographics $regional  i.month if  weekend==0 & phase != 0 & phase !=6 [aw=kr_ew_20], cluster(ags5) 

 qui estadd local time "x", replace
 qui estadd local p_control "x", replace
 qui estadd local se_control "x", replace
 qui estadd local i_control "x", replace
 qui estadd local d_control "x", replace
 qui estadd local r_control "x", replace
 qui estadd scalar r2_est= e(r2)


eststo: reg MobilityD `x' $pandemic $socio_eco $infrastructur $demographics $regional  i.month  if weekend ==1 & phase != 0 & phase !=6 [aw=kr_ew_20] , cluster(ags5) 

 qui estadd local time "x", replace
 qui estadd local p_control "x", replace
 qui estadd local se_control "x", replace
 qui estadd local i_control "x", replace
 qui estadd local d_control "x", replace
 qui estadd local r_control "x", replace
 qui estadd scalar r2_est= e(r2)

 *Table S3: Average decrease in mobility associated with digitalisation considering mobility changes over the entire day, daytime mobility changes, nighttime mobility changes as well as differences between working days and weekends during the two pandemic years

esttab using "..\Mobility\Tables\main_results_`x'_short.txt", keep(`x' )   tex s(time p_control se_control i_control d_control r_control N r2_est, label("year-month fixed effects" "pandemic controls"  "socioeconomic controls" "infrastructure controls"  "demographic controls"   "geographic controls" "observations" "\(R^{2}\) ")) t  addnotes ( "Clustered standard errors.") substitute(\_ _) label nogap replace star(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

}


** comparison with WfH potential **

est clear


eststo: reg MobilityD kr_ho_pot_ao   $pandemic  $socio_eco $infrastructur $demographics $regional  i.month [aw=kr_ew_20] , cluster(ags5)

estadd local time "x", replace
estadd local se_control "x", replace
estadd local i_control "x", replace
estadd local d_control "x", replace
estadd local r_control "x", replace
estadd scalar ar2_est= e(r2_a)

eststo: reg MobilityD kr_ho_pot_ao WI_19   $pandemic  $socio_eco $infrastructur $demographics $regional  i.month  [aw=kr_ew_20]  , cluster(ags5)

estadd local time "x", replace
estadd local se_control "x", replace
estadd local i_control "x", replace
estadd local d_control "x", replace
estadd local r_control "x", replace
estadd scalar ar2_est= e(r2_a)

*Table S8: Equation 3 with digitalisation replaced by a region’s WfH potential. Only working days and daytime mobility changes are consided
esttab using "..\Mobility\Tables\wfh_potential.txt", drop(*.month   $pandemic  $socio_eco $infrastructur $demographics $regional  ) tex s(time se_control i_control d_control r_control N ar2_est, label("year-month fixed effects"  "socioeconomic controls" "infrastructure controls"  "demographic controls"   "geographic controls" "observations" "adjusted \(R^{2}\) ")) t  addnotes ( "Clustered standard errors.") substitute(\_ _) label nogap star(+ 0.10 * 0.05 ** 0.01 *** 0.001)  replace


** robustness checks

xtset ags5 day_count

est clear

gen digitalisation=.

foreach x in  WI_19_zero WI_22_zero diff22_zero  mbits50  {

replace digitalisation = `x'
 	
	eststo: xtreg Mobility io1.phase##c.digitalisation io1.phase#c.($pandemic) io1.phase#c.($socio_eco) io1.phase#c.($infrastructur) io1.phase#c.($demographics) io1.phase#c.($regional) i.month   [aw=kr_ew_20]  , fe cluster(ags5) 

	 qui estadd local time "x", replace
	 qui estadd local p_control "x", replace
	 qui estadd local se_control "x", replace
	 qui estadd local i_control "x", replace
	 qui estadd local d_control "x", replace
	 qui estadd local r_control "x", replace
	 qui estadd scalar r2_est= e(r2)
}

replace digitalisation = WI_19

	eststo: xtreg Mobility io1.phase##c.digitalisation io1.phase#c.($pandemic) io1.phase#c.($socio_eco) io1.phase#c.($infrastructur) io1.phase#c.($demographics) io1.phase#c.($regional) i.month  , fe cluster(ags5) 

	qui estadd local time "x", replace
	 qui estadd local p_control "x", replace
	 qui estadd local se_control "x", replace
	 qui estadd local i_control "x", replace
	 qui estadd local d_control "x", replace
	 qui estadd local r_control "x", replace
	 qui estadd scalar r2_est= e(r2)
	 
replace digitalisation = WI_22

	eststo: xtreg Mobility io1.phase##c.digitalisation io1.phase#c.($pandemic) io1.phase#c.($socio_eco) io1.phase#c.($infrastructur) io1.phase#c.($demographics) io1.phase#c.($regional) i.month  , fe cluster(ags5) 
	
		 qui estadd local time "x", replace
	 qui estadd local p_control "x", replace
	 qui estadd local se_control "x", replace
	 qui estadd local i_control "x", replace
	 qui estadd local d_control "x", replace
	 qui estadd local r_control "x", replace
	 qui estadd scalar r2_est= e(r2)

*Table S5: Further robustness checks

esttab using "..\Mobility\Tables\firm_robust_time.txt", keep(*.phase#c.digitalisation ) tex s(time p_control se_control i_control d_control r_control N r2_est, label("day-level fixed effects" "pandemic controls"  "socioeconomic controls" "infrastructure controls"  "demographic controls"   "geographic controls" "observations" "\(R^{2}\) ")) t  addnotes ( "Clustered standard errors.") substitute(\_ _) label nogap replace  star(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

 pwcorr WI_19 WI_22 in_commuters, sig
 
 pwcorr WI_19 WI_22 in_commuters [aw=kr_ew_20], sig

log close








