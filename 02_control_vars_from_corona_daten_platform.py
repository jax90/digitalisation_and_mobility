# -*- coding: utf-8 -*-
"""
Created on Thu Jun  2 09:32:17 2022

@author: JAX
"""


import pandas as pd 


path=

bip= pd.read_csv()
bip = bip[['ags5', 'kr_bip_ew']]


density= pd.read_csv( )
density=density[['ags5', 'kr_ew_dichte']]


edu= pd.read_csv( )
edu = edu[['ags5', 'kr_beruf_hochschul', 'kr_beruf_prom']]

ew= pd.read_csv(path)
ew = ew[['ags5', 'kr_ew_20', 'kr_ew_60', 'kr_ew_00u03', 
         'kr_ew_03u06', 'kr_ew_06u10', 'kr_ew_10u15', 'kr_ew_15u18', 'kr_ew_18u20',
         'kr_ew_20u25', 'kr_ew_25u30', 'kr_ew_30u35', 'kr_ew_35u40' ,'kr_ew_40u45',
         'kr_ew_45u50', 'kr_ew_50u55', 'kr_ew_55u60','kr_ew_35u60','kr_ew_65u75', 'kr_ew_75','kr_ew_m',
         ]]


am= pd.read_csv(path + r"\raw\arbeitsmarktstruktur.csv")
am = am[['ags5','kr_dl_qu',  'kr_ho_pot_wo', 'kr_ho_pot_ao', 'kr_erwt_ao', 'kr_be_ao', 'kr_be_wo', 'kr_erwt_ao_b8']]


fl= pd.read_csv(path )
fl = fl[['ags5','kr_flaeche']]

df = bip.merge(edu, on = 'ags5').merge(ew, on = 'ags5').merge(density, on = 'ags5').merge(fl, on = 'ags5').merge(am, on = 'ags5')

haushalte= pd.read_csv(path + r"\raw\haushalte.csv")
haushalte = haushalte[['ags5','kr_hh_1p']]
df = df.merge(haushalte, on = 'ags5')


private_finanzen= pd.read_csv(path + r"\raw\private_finanzen.csv")
private_finanzen = private_finanzen[['ags5','kr_hh_eink_kl1','kr_hh_eink_kl2' ]]
df = df.merge(private_finanzen, on = 'ags5')

raumordnung= pd.read_csv(path + r"\raw\raumordnung.csv")
raumordnung = raumordnung[['ags5','kr_wo_kl']]
df = df.merge(raumordnung, on = 'ags5')

sozialindikatoren= pd.read_csv(path + r"\raw\sozialindikatoren.csv")
sozialindikatoren = sozialindikatoren[['ags5','kr_sgb_qu']]
df = df.merge(sozialindikatoren, on = 'ags5')


wohnsituation= pd.read_csv(path + r"\raw\wohnsituation.csv")
wohnsituation = wohnsituation[['ags5','kr_wfl']]
df = df.merge(wohnsituation, on = 'ags5')



verkehr= pd.read_csv(path + r"\raw\verkehr.csv")
verkehr = verkehr[['ags5', "bundesland", 
                   'kr_pkw_dichte']]
df = df.merge(verkehr, on = 'ags5')


point_of_interest= pd.read_csv(path + r"\raw\point_of_interest.csv")
point_of_interest = point_of_interest[['ags5','kr_rest', 'kr_poi_4' ]]
df = df.merge(point_of_interest, on = 'ags5')


df.to_stata(path + r"\prepared\control_vars.dta")


# kurzarbeit= pd.read_csv(path + "arbeitsmarktentwicklung.csv")
# kurzarbeit = kurzarbeit[['ags5', "datum", 'kr_ka_au', 'kr_ka_ap', 'kr_ka_ru', 'kr_ka_rp']]
# kurzarbeit.dropna(subset=["kr_ka_au"], inplace=True)
# kurzarbeit.datum= kurzarbeit.datum.str.replace("-","").astype(int)
# kurzarbeit = kurzarbeit[kurzarbeit.datum > 202000]
# kurzarbeit["month"] = kurzarbeit.datum
# kurzarbeit.to_stata(path + "kurzarbeit.dta")




