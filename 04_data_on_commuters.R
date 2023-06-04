library(readxl)
library(tidyverse)
library(data.table)
library(readxlsb)

##2021##

path <- 
#set wd for 2021 data. I put the data for 2021,2020 and 2021 in seperate folders since they all have the same name, so that makes the reading easier
setwd(paste0(path,"/raw/Pendlerdaten/2021"))

#Auspendler 2021#

#read all the excel files for each federal state and combine into one dataframe
file.list <- list.files(pattern='*.xlsx')
df.list <- lapply(file.list, read_excel,sheet=3,skip=6,col_names = TRUE)

df <- rbindlist(df.list, idcol = "id")

#sort out the relevant variables
dataAuspendler_2021 = df%>% 
  rename(ags5 = Wohnort)%>%
  fill(ags5)%>%
  group_by(ags5)%>%
  filter(Arbeitsort == "Z") %>%  # the row next to the row of the colum Arbeitsort with the value "Z" contains the "insgesamt" count, see excel sheet for details
  rename(out_commuters = Insgesamt)


dataAuspendler_2021 = select(dataAuspendler_2021,c(2,6))
dataAuspendler_2021["Jahr"] = 2021  #create year colum

remove(file.list,df.list,df) #clearing
 
#Einpendler 2021# #same process as before
file.list <- list.files(pattern='*.xlsx')
df.list <- lapply(file.list, read_excel,sheet=4,skip=6,col_names = TRUE)

df <- rbindlist(df.list, idcol = "id")


dataEinpendler_2021 = df%>% 
  rename(ags5 = Arbeitsort)%>% #switch Arbeitsort and Wohnort compared to Auspendler, look at excl sheet for details
  fill(ags5)%>%
  group_by(ags5)%>%
  filter(Wohnort == "Z")%>%
  rename(in_commuters = Insgesamt)


dataEinpendler_2021 = select(dataEinpendler_2021,c(2,6))
dataEinpendler_2021["Jahr"] = 2021

remove(file.list,df.list,df)

#Pendler2021#

#merge data for Einpendler and Auspendler by ags5
dataPendler2021 = inner_join(dataEinpendler_2021,dataAuspendler_2021,by = "ags5")%>%
  rename(Jahr = Jahr.y)
dataPendler2021 = select(dataPendler2021,-3)



##2020##
setwd(paste0(path,"/raw/Pendlerdaten/2020"))

#Auspendler 2020#
file.list <- list.files(pattern='*.xlsb*')
df.list <- lapply(file.list, read_xlsb,sheet=3,skip=6,col_names = TRUE)


df <- rbindlist(df.list, idcol = "id")


dataAuspendler_2020 = df%>%
  mutate_all(na_if,"")%>%
  rename(ags5 = Wohnort)%>%
  fill(ags5)%>%
  group_by(ags5)%>%
  filter(Arbeitsort == "Z")%>%
  rename(out_commuters = Insgesamt)


dataAuspendler_2020 = select(dataAuspendler_2020,c(2,6))
dataAuspendler_2020["Jahr"] = 2020

remove(file.list,df.list,df)

#Einpendler 2020#
file.list <- list.files(pattern='*.xlsb')
df.list <- lapply(file.list, read_xlsb,sheet=4,skip=6,col_names = TRUE)

df <- rbindlist(df.list, idcol = "id")


dataEinpendler_2020 = df%>%
  mutate_all(na_if,"")%>%
  rename(ags5 = Arbeitsort)%>%
  fill(ags5)%>%
  group_by(ags5)%>%
  filter(Wohnort == "Z")%>%
  rename(in_commuters = Insgesamt)


dataEinpendler_2020 = select(dataEinpendler_2020,c(2,6))
dataEinpendler_2020["Jahr"] = 2020

remove(file.list,df.list,df)

#Pendler2020#

dataPendler2020 = inner_join(dataEinpendler_2020,dataAuspendler_2020,by = "ags5")%>%
  rename(Jahr = Jahr.y)
dataPendler2020 = select(dataPendler2020,-3)


##2019##

setwd(paste0(path,"/raw/Pendlerdaten/2019"))

#Auspendler 2019#
file.list <- list.files(pattern='*.xlsb*')
df.list <- lapply(file.list, read_xlsb,sheet=3,skip=6,col_names = TRUE)


df <- rbindlist(df.list, idcol = "id")


dataAuspendler_2019 = df%>%
  mutate_all(na_if,"")%>%
  rename(ags5 = Wohnort)%>%
  fill(ags5)%>%
  group_by(ags5)%>%
  filter(Arbeitsort == "Z")%>%
  rename(out_commuters = Insgesamt)


dataAuspendler_2019 = select(dataAuspendler_2019,c(2,6))
dataAuspendler_2019["Jahr"] = 2019

remove(file.list,df.list,df)

#Einpendler 2019#
file.list <- list.files(pattern='*.xlsb')
df.list <- lapply(file.list, read_xlsb,sheet=4,skip=7,col_names = TRUE)#skip first 7 and not 6 lines here due to comment in excel sheet

df <- rbindlist(df.list, idcol = "id")


dataEinpendler_2019 = df%>%
  mutate_all(na_if,"")%>%
  rename(ags5 = Arbeitsort)%>%
  fill(ags5)%>%
  group_by(ags5)%>%
  filter(Wohnort == "Z")%>%
  rename(in_commuters = Insgesamt)


dataEinpendler_2019 = select(dataEinpendler_2019,c(2,6))
dataEinpendler_2019["Jahr"] = 2019

remove(file.list,df.list,df)

#Pendler2019#

dataPendler2019 = inner_join(dataEinpendler_2019,dataAuspendler_2019,by = "ags5")%>%
  rename(Jahr = Jahr.y)
dataPendler2019 = select(dataPendler2019,-3)


##Pendler 2019-2021 Merge##

dataPendler = bind_rows(dataPendler2019,dataPendler2020,dataPendler2021)%>%
  arrange(ags5)%>%
  rename(jahr = Jahr)

dataPendler <- dataPendler %>% pivot_wider(
              id_cols = c(ags5),
              names_from = jahr,
              values_from = c(in_commuters,out_commuters)
 #             names_prefix = "exp.change_"
              )

dataPendler <- dataPendler %>%  
  mutate(across(everything(), as.numeric))
  
dataPendler$ags5 <-  dataPendler$ags5 %>% as.numeric()         

haven::write_dta(dataPendler,paste0(path,"/prepared/pendler.dta"))

