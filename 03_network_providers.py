# -*- coding: utf-8 -*-
"""
Created on Wed Dec 14 15:19:44 2022

@author: JAX
"""


import pandas as pd
import difflib 
import tabula

path = 

df = tabula.read_pdf(path + r"\raw\202210_Auswertung_Kreisebene.pdf", multiple_tables=True, pages="all")

names= df[0].columns
df_combine=pd.DataFrame()

for page in range(0,len(df)):
    df[page].columns = names
    df_combine = pd.concat([df_combine,df[page]])
    
    
df_combine = df_combine.dropna(subset=["Unnamed: 0"]).reset_index()   


ags =  pd.read_csv(path + r"\raw\\besiedlung.csv")[["kreis","ags5"]].reset_index()

matched = ags.merge(df_combine, left_on="kreis", right_on="Unnamed: 0", how="inner" , indicator=True)

test = ags.merge(df_combine, left_on="kreis", right_on="Unnamed: 0", how="outer" , indicator=True)

df_names = test[test._merge== "right_only"]["Unnamed: 0"].to_list()
ags_names = test[test._merge== "left_only"]["kreis"].to_list()


matches = {}

                   
for krs in range(0, len(df_names)):
    matches[ df_names[krs]]= difflib.get_close_matches( df_names[krs], ags_names, n=1, cutoff=0.8)
 
matches =    {k:v for k,v in matches.items() if v}
del matches['Cottbus, Stadt']
    
df_combine2 = df_combine

df_combine2["kreis2"] = df_combine2["Unnamed: 0"].map(matches)
df_combine2 = df_combine2.dropna(subset=["kreis2"])

df_combine2["kreis2"] = df_combine2["kreis2"].apply(lambda x: x[0])

matched2 = ags.merge(df_combine2, left_on="kreis", right_on="kreis2", how="inner" )



#create duplicate column to retain team name from df2

matchedvalues = [item[0] for item in list(matches.values())]
test = test[~test['kreis'].isin(matchedvalues)]

matchedvalues = list(matches.keys())
test = test[~test['Unnamed: 0'].isin(matchedvalues)]

test['kreis'] = test['kreis'].str.replace('kreisfreie Stadt', '')
test['kreis'] = test['kreis'].str.replace(', Stadt', '')
test['kreis'] = test['kreis'].str.replace(', Kreis', '')
test['kreis'] = test['kreis'].str.replace(', Landeshauptstadt', '')
test['kreis'] = test['kreis'].str.replace(', Hansestadt', '')
test['kreis'] = test['kreis'].str.replace('Stadt', '')
test['kreis'] = test['kreis'].str.replace(',', '')
test['kreis'] = test['kreis'].str.replace('Kreisfreie', '')
test['kreis'] = test['kreis'].str.replace('Landkreis', '')
test['kreis'] = test['kreis'].str.replace('Landeshauptstadt', '')


test["Unnamed: 0"] = test["Unnamed: 0"].str.replace('kreisfreie Stadt', '')
test["Unnamed: 0"] = test["Unnamed: 0"].str.replace(', Stadt', '')
test["Unnamed: 0"] = test["Unnamed: 0"].str.replace(', Kreis', '')
test["Unnamed: 0"] = test["Unnamed: 0"].str.replace(', Landeshauptstadt', '')
test["Unnamed: 0"] = test["Unnamed: 0"].str.replace(', Hansestadt', '')
test["Unnamed: 0"] = test["Unnamed: 0"].str.replace(',', '')
test["Unnamed: 0"] = test["Unnamed: 0"].str.replace('Stadt', '')
test["Unnamed: 0"] = test["Unnamed: 0"].str.replace('Wissenschaftsstadt', '')
test["Unnamed: 0"] = test["Unnamed: 0"].str.replace('Freie und Hansestadt', '')
test["Unnamed: 0"] = test["Unnamed: 0"].str.replace('documenta', '')
test["Unnamed: 0"] = test["Unnamed: 0"].str.replace('an der Weinstraße', '')
test["Unnamed: 0"] = test["Unnamed: 0"].str.replace('Städteregion', '')
test["Unnamed: 0"] = test["Unnamed: 0"].str.replace('Ulmkreis', 'Ulm')
test["Unnamed: 0"] = test["Unnamed: 0"].str.replace('Solingen Klingenstadt', 'Solingen')
test["Unnamed: 0"] = test["Unnamed: 0"].str.replace('Region', '')
test["Unnamed: 0"] = test["Unnamed: 0"].str.replace('der FernUniversität', '')


df_names = test[test._merge== "right_only"]["Unnamed: 0"].to_list()
ags_names = test[test._merge== "left_only"]["kreis"].to_list()


matches = {}

                   
for krs in range(0, len(df_names)):
    matches[ df_names[krs]]= difflib.get_close_matches( df_names[krs], ags_names, n=1, cutoff=0.7)

matches =    {k:v for k,v in matches.items() if v}

a = test[test._merge== "right_only"] 
b = test[test._merge== "left_only"] 
a["kreis2"] = a["Unnamed: 0"].map(matches)
a = a.dropna(subset=["kreis2"])
a["kreis2"] = a["kreis2"].apply(lambda x: x[0])

matched3 = b[["kreis", "ags5"]].merge(a[["kreis2", "Graue", "Weiße" ]], left_on="kreis", right_on="kreis2", how="inner" )


matchedvalues = [item[0] for item in list(matches.values())]
test = test[~test['kreis'].isin(matchedvalues)]

matchedvalues = list(matches.keys())
test = test[~test["Unnamed: 0"].isin(matchedvalues)]

test= test[test._merge!= "both"] 

matched = matched[["ags5", "Graue", "Weiße"]]
matched2 = matched2[["ags5", "Graue", "Weiße"]]
matched3 = matched3[["ags5", "Graue", "Weiße"]]


df = pd.concat([matched, matched2, matched3])  
 
df[["Graue", "Weiße"]] =  df[["Graue", "Weiße"]].astype(str)

df["not_every_provider"] = df["Graue"].apply(lambda x: x[:-1]).str.replace(",",".").astype(float) 
df["no_signal"] = df["Weiße"].apply(lambda x: x[:-1]).str.replace(",",".").astype(float)  

df[["ags5","not_every_provider","no_signal"]].to_stata(path + r"\prepared\network_providers.dta")
#convert team name in df2 to team name it most closely matches in df1
#merge the DataFrames into one
