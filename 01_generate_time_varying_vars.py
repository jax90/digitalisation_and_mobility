# -*- coding: utf-8 -*-
"""
Created on Wed Nov 16 16:05:52 2022

@author: JAX
"""


import pandas as pd 
pd.set_option('display.max_columns', 500)

path= 

df = pd.read_excel(path + r"\raw\Mobilitätsveränderung_Kreise_TagNacht.xlsx", sheet_name = "Daten" )

df["weekday"] =df["Datum"].dt.day_name()
df["Datum"] = df.Datum.astype(str).str.replace("-","").astype(int)

df = df.rename(columns= {'AGS5': 'ags5', "KR_MV_T":"MobilityD","KR_MV_N":"MobilityN", "Datum": "day"})
df.to_stata(path + r"\prepared\mobility_new.dta")

#inzidenz 

#https://www.corona-daten-deutschland.de/dataset/infektionen


filename= path + r"\raw\infektion_new.csv"
inf= pd.read_csv(filename, sep=",")
inf["datum"] = inf.datum.astype(str).str.replace("-","").astype(int)
inf = inf.rename(columns= { "datum": "day"})

inf.to_stata(path + r"\prepared\infektionen_prepared_new.dta")

filename= path + r"\raw\kr_massnahmen_index_tag.csv"
index= pd.read_csv(filename, sep=",")
index["datum"] = index.datum.astype(str).str.replace("-","").astype(int)
index = index.rename(columns= { "datum": "day"})
index = index[["ags5",'day', 'kr_mn_idx_t']]

index.to_stata(path + r"\prepared\restrictions.dta")
