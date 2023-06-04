# -*- coding: utf-8 -*-
"""
Created on Thu Nov 17 17:34:26 2022

@author: jax
"""

import pandas as pd 


df = pd.read_csv()
df2 = pd.read_csv()
df22pred = pd.read_csv()

df2.kreis = df2.kreis.replace( 3156, 3159)
df2.kreis = df2.kreis.replace( 3152, 3159)


df22 = df2[['id', 'kreis']].merge(df22pred[["id","prediction_1"]], on = "id")

mup = pd.read_stata()
mup.kreisnr = mup.kreisnr.replace( 3156, 3159)
mup.kreisnr = mup.kreisnr.replace( 3152, 3159)

df= df.merge(mup, left_on = "id", right_on= "crefo")
df = df.rename(columns= {'prediction_1': 'WI_19',"kreisnr": "ags5"})
df22 = df22.rename(columns= {'prediction_1': 'WI_22', "kreis": "ags5 2022"})

#compare all firms                       
mrg = df.merge(df22, on = "id", how="outer")

#compare only firms that are observed in both periods
mrg2 = df.merge(df22, on = "id", how="inner")


# mrg["WI_19_emp"] = mrg.WI_19*mrg.ma_2020

# mrg["WI_19_emp"] = mrg.groupby('ags5', sort=False)['WI_19_emp'].transform('sum')


# ma = mrg.groupby('ags5', sort=False)['ma_2020'].sum().reset_index()\
#     .rename(columns={"ma_2020" : "ma_2020_total"})
# mrg =  ma.merge(mrg, on = "ags5")

# mrg["WI_19_emp"] = mrg["WI_19_emp"]/mrg["ma_2020_total"] 



mrg= mrg[[ 'crefo', 'WI_19', 'WI_22', "ags5 2022"]]\
    .merge(mup[["kreisnr", "crefo"]], on= "crefo", how ="left")\
    .rename(columns= {"kreisnr": "ags5"})

mrg2= mrg2[[ 'crefo', 'WI_19', 'WI_22']]\
    .merge(mup[["kreisnr", "crefo"]], on= "crefo", how ="left")\
    .rename(columns= {"kreisnr": "ags5"})


mrg2["diff_firm_level"] =  mrg2["WI_22"] - mrg2["WI_19"]

#for the standard indicator
ags= mrg.groupby('ags5')["WI_19"].mean().reset_index()\
    .merge(
        mrg.groupby('ags5 2022')["WI_22"].mean().reset_index().rename(columns= {"ags5 2022": "ags5"}
                                                                      ),
        on = "ags5" )
    
#for the modified indicator
total= mrg.groupby('ags5')["WI_19"].sum().reset_index()\
    .merge(
        mrg.groupby('ags5 2022')["WI_22"].sum().reset_index().rename(columns= {"ags5 2022": "ags5"}
                                                                      ),
        on = "ags5" )

total.columns = ["ags5","WI_19 sum", "WI_22 sum" ]

nr_of_firms = pd.read_csv()

ags = nr_of_firms[["ags5","kr_firm"]].merge(ags, on = "ags5", how="outer").merge(total, on = "ags5")

#calculate mobified indicator
ags["WI_19_zero"] = ags["WI_19 sum"] /ags["kr_firm"]
ags["WI_22_zero"] = ags["WI_22 sum"] /ags["kr_firm"]


# for comparing changes in firm digitalisation
ags2= mrg2.groupby("ags5")["diff_firm_level"].mean().reset_index()\
    .merge(
        mrg.groupby('ags5')["WI_19"].count().reset_index().rename(columns= {"WI_19": "number of firms 2019"}
                                                                      ),on = "ags5" )\
        .merge (mrg.groupby('ags5 2022')["WI_22"].count().reset_index().rename(columns= {"ags5 2022": "ags5", "WI_22": "number of firms 2022" })\
            
                                                       , on= "ags5")
            
ags2["diff_number"] = ags2["number of firms 2022"]- ags2["number of firms 2019"]    

#combine all variables
ags= ags.merge(ags2[["ags5", "diff_firm_level", "diff_number"]], on = "ags5")  

#save
ags[['ags5', 'WI_19', 'WI_22', 'WI_19_zero' , 'WI_22_zero', 'diff_firm_level',  'diff_number']]\
    .to_stata()
