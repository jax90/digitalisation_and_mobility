library(haven)
library(plyr) 
library(cowplot)
library(lattice)
library(ggrepel)
library(hrbrthemes)
library(viridis)
library(lubridate)
library(scales)
library(RCurl)
library(estimatr)
library(broom)
library(sp)
library(RColorBrewer)
library(rgeos)
library(maptools)
library(gpclib)
library(tidyverse)

setwd()

Sys.setlocale("LC_ALL","English")

#germany <- readShapeSpatial("./Data/map/vg2500_krs.shp")
#germany<- fortify(germany, region = "RS")

#upload data

df <- read_dta("./Data/merged_file.dta")


# process variables
df <- df %>% 
  group_by(week, ags5) %>% 
  mutate(M_week = mean(Mobility, na.rm=TRUE )) %>% 
  ungroup %>% 
  mutate(q5WI_19 = as.character(ntile(WI_19, 5)) )  %>% 
  mutate(q5WI_22 = as.character(ntile(WI_22, 5)) )  %>% 
  mutate(q5kr_ho_po_ao = as.character(ntile(kr_ho_pot_ao, 5)) )  %>% 
  mutate(Mean_overall  = mean(as.numeric(Mobility), na.rm=TRUE ))
  

df <- df %>% mutate(date = ymd(day)) 

df <- df %>% 
  mutate(month_factor = relevel(as.factor(month), ref = "202002")) %>% 
  mutate(week_factor = relevel(as.factor(week), ref = "11")) %>% 
  mutate(land_factor = as.factor(land_int)) %>% 
  mutate(ags5_factor = as.factor(ags5)) %>% 
  arrange(date)



df_digital <- df %>%
  pivot_longer(
    cols = c('WI_19', 'WI_22'),
    names_to = "independent_variable",
    values_to = "digital",
  ) %>% select(date, ags5, Mobility, month_factor, independent_variable, digital) %>% 
  arrange(date) %>% 
  mutate(ags5 = if_else(ags5==3159, 3156, ags5))

germany <- 
  sf::st_read("./Data/map/vg2500_krs.shp") %>% 
  mutate(ags5 = as.double(RS)) %>% 
  mutate(ags5 = if_else(ags5==3152, 3156, ags5)) %>% 
  mutate(ags5 = if_else(ags5==16056, 16063, ags5)) %>% 
  left_join(distinct(df_digital,independent_variable,  ags5, .keep_all = TRUE), by="ags5")

digi_map <-germany %>% 
  drop_na(independent_variable) %>% 
  ggplot() +
  geom_sf(aes(fill=digital),  color = NA) +
  scale_fill_gradientn(colours = rev(terrain.colors(10)), na.value="white") +
  labs(fill='digitalisation')  +
  theme_void() +
  theme(text=element_text(size=20,  family="serif"), legend.position="bottom", strip.text = element_text(size = 20, vjust = 1.0))  +
  facet_wrap(vars(independent_variable), ncol=2, 
             labeller = as_labeller(c("WI_19"= "January 2020","WI_22" ="December 2022")))


# Figure 2: Regional distribution in January 2020 and in December 2022 of the web-based firm digitalisation indicator. Values are standardised.
ggsave("./Figures/map_digi.png", digi_map,
       width = 210, height = 297, unit = "mm")


time_plot <-df %>% 
  arrange(date) %>% 
  select(M_week , ags5 , Mobility, week, date, WI_19 ) %>% 
  drop_na(M_week, WI_19) %>% 
  arrange(date) %>% 
  distinct(ags5, week, .keep_all = TRUE) 

# 
# mj <- time_plot %>% 
#   arrange(WI_19) %>% 
#   ggplot(aes(x=date, y=M_week, color= WI_19)) +
#   geom_rect(aes(xmin=as.Date("2020-03-22", "%Y-%m-%d"), xmax=as.Date("2020-05-04", "%Y-%m-%d"), ymin=-Inf, ymax=Inf, fill="grey" ),
#             color = alpha("grey", .01) , 
#             fill = alpha("grey", .01)) +
#   geom_rect(aes(xmin=as.Date("2020-11-02", "%Y-%m-%d"), xmax=as.Date("2021-01-26", "%Y-%m-%d"), ymin=-Inf, ymax=Inf,  fill="grey"), 
#             color = alpha("grey", .01) , 
#             fill = alpha("grey", .01)) +
#   geom_rect(aes(xmin=as.Date("2021-01-27", "%Y-%m-%d"), xmax=as.Date("2021-06-30", "%Y-%m-%d"), ymin=-Inf, ymax=Inf, fill="#6DBCC3"), 
#             color = alpha("#6DBCC3", .01) , 
#             fill = alpha("#6DBCC3", .01)) +
#   geom_rect(aes(xmin=as.Date("2021-11-24", "%Y-%m-%d"), xmax=as.Date("2022-03-19", "%Y-%m-%d"), ymin=-Inf, ymax=Inf, fill="#6DBCC3"), 
#             color = alpha("#6DBCC3", .01) , 
#             fill = alpha("#6DBCC3", .01)) +
#   geom_point(size = 1.5) +
#   geom_hline(yintercept = 0) +
#   geom_vline(xintercept = as.numeric(as.Date("2020-03-22")), size = 1, color="red") + 
#   scale_colour_gradientn(colours = rev(terrain.colors(10))) +
#   ylab("weekly change in mobility") +
#   xlab("time") +
#   labs(color='digitalisation')  +
#   theme_bw() +
#   scale_y_continuous(breaks= pretty_breaks(3)) +
#   theme(legend.position="bottom", text=element_text(size=10,  family="serif")) 
# 
# 
# #Figure 3: Weekly changes in mobility per district over the observed time frame.
# ggsave("./Figures/relationship_over_time.png",mj,
#        width = 297, height = 150, unit = "mm")
# 


time_plot <-df %>% 
  arrange(date) %>% 
  select(M_week , ags5 , Mobility, week, date, WI_22 ) %>% 
  drop_na(M_week, WI_22) %>% 
  arrange(date) %>% 
  distinct(ags5, week, .keep_all = TRUE) 





control_vars <- c(#pandemic
                  "kr_inz_rate" , "kr_mn_idx_t",
                  # socio-eco
                  "edu_hoch" , "kr_bip_ew" ,  "kr_hh_eink_kl1" , "kr_sgb_qu" , "service_sector",
                  #infrastructure
                  "kr_pkw_dichte" , "mbits50" ,   "not_every_provider" , "missing_info_provider" , "no_signal" ,
                  # demographic characteristics
                  "share_men" ,  "non_workers" , "kr_ew_20" ,"change_pop" , "kr_ew_dichte" , 
                  "out_commuters" , "in_commuters" ,  "kr_hh_1p" , "kr_wfl" ,
                  # regional
                  "kr_wo_kl" , "kr_typ" )




vars_did <-c("WI_19",  control_vars)


form_list <- list( 
  "a" = Mobility ~ WI_19 + ags5 + month_factor + month_factor:WI_19,
  "b" = as.formula(
  str_c("Mobility ~ ags5 + ", str_c(str_c(vars_did, "month_factor", sep="*"), collapse="+"))
 )
)


model_list <- purrr::map(form_list, function(form){
  lm_robust(formula=form, data=df, cluster=ags5,  se_type = 'stata', weights=kr_ew_20 )
})

sum <- model_list %>% 
  map_dfr(broom::tidy, .id="model_name") %>% 
  as_tibble()%>% 
  filter(str_detect(term, "month_factor" ))  %>% 
  filter(str_detect(term, "WI_" )) %>% 
  mutate(month= str_sub(term, start= -6)) %>%  
  left_join(df %>% 
              select(month, date) %>% 
              mutate(month = as.character(month)), by = "month") %>% 
  arrange(date) %>% 
  distinct( month, model_name, .keep_all = TRUE)


label_names= c("a" = "Panel A: only digitalisation interacted with time dummies",
                "b" = "Panel B: all variables interacted with time dummies")

pd <- position_dodge(width=20)


coef <-  sum %>% 
  ggplot(aes(x=date, y=estimate)) + 
  geom_rect(aes(xmin=as.Date("2020-03-22", "%Y-%m-%d"), xmax=as.Date("2020-05-04", "%Y-%m-%d"), ymin=-Inf, ymax=Inf, fill="grey" ),
            color = alpha("grey", .01) , 
            fill = alpha("grey", .01)) +
  geom_rect(aes(xmin=as.Date("2020-11-02", "%Y-%m-%d"), xmax=as.Date("2021-01-26", "%Y-%m-%d"), ymin=-Inf, ymax=Inf,  fill="grey"), 
            color = alpha("grey", .01) , 
            fill = alpha("grey", .01)) +
  geom_rect(aes(xmin=as.Date("2021-01-27", "%Y-%m-%d"), xmax=as.Date("2021-06-30", "%Y-%m-%d"), ymin=-Inf, ymax=Inf, fill="#6DBCC3"), 
            color = alpha("#6DBCC3", .01) , 
            fill = alpha("#6DBCC3", .01)) +
  geom_rect(aes(xmin=as.Date("2021-11-24", "%Y-%m-%d"), xmax=as.Date("2022-03-19", "%Y-%m-%d"), ymin=-Inf, ymax=Inf, fill="#6DBCC3"), 
            color = alpha("#6DBCC3", .01) , 
            fill = alpha("#6DBCC3", .01)) +
  geom_hline(yintercept = 0) +
  geom_vline(xintercept = as.numeric(as.Date("2020-03-22")), size = 1, color="red") +
  geom_errorbar(aes(ymin= estimate - 1.645*std.error , ymax=estimate + 1.645*std.error),position=pd) +
  geom_point(position=pd, size=3) +
  ylab("monthly change in mobility associated with digitalisation") +
  xlab("time") +
  labs(color='digitalisation')  +
  theme_bw() +
  geom_line(position=pd) +
  facet_wrap(vars(model_name), ncol=2, labeller =  as_labeller(label_names)) +
  theme(legend.position="bottom", 
        text=element_text(size=14,  family="serif"),
        strip.text = element_text(size = 14),
        legend.text=element_text(size=14)) # +
 

#Figure 4: Monthly decrease in mobility associated with digitalisation.
  ggsave("./Figures/relationship_over_time_estimated_2020_dp.png", coef,
         width = 297, height = 150, unit = "mm")
  
  
 
  vars22 <-c("WI_22",  control_vars)
  
  
  form_list22 <- list( 
    "a" = Mobility ~ WI_22 + ags5 + month_factor + month_factor:WI_22,
    "b" = as.formula(
      str_c("Mobility ~ ags5 + ", str_c(str_c(vars22, "month_factor", sep="*"), collapse="+"))
    )
  )
  
  model_list22 <- purrr::map(form_list22, function(form){
    lm_robust(formula=form, data=df, cluster=ags5,  se_type = 'stata', weights= kr_ew_20)
  })
  
  sum22 <- model_list22 %>% 
    map_dfr(broom::tidy, .id="model_name") %>% 
    as_tibble()%>% 
    filter(str_detect(term, "month_factor" ))  %>% 
    filter(str_detect(term, "WI_" )) %>% 
    mutate(month= str_sub(term, start= -6)) %>%  
    left_join(df %>% 
                select(month, date) %>% 
                mutate(month = as.character(month)), by = "month") %>% 
    arrange(date) %>% 
    distinct( month, model_name, .keep_all = TRUE)
  

  label_names= c("a" = "Panel A: only digitalisation interacted with time dummies",
                 "b" = "Panel B: all variables interacted with time dummies")
  
  pd <- position_dodge(width=20)
  
  
  coef <-  sum22 %>% 
    ggplot(aes(x=date, y=estimate)) + 
    geom_rect(aes(xmin=as.Date("2020-03-22", "%Y-%m-%d"), xmax=as.Date("2020-05-04", "%Y-%m-%d"), ymin=-Inf, ymax=Inf, fill="grey" ),
              color = alpha("grey", .01) , 
              fill = alpha("grey", .01)) +
    geom_rect(aes(xmin=as.Date("2020-11-02", "%Y-%m-%d"), xmax=as.Date("2021-01-26", "%Y-%m-%d"), ymin=-Inf, ymax=Inf,  fill="grey"), 
              color = alpha("grey", .01) , 
              fill = alpha("grey", .01)) +
    geom_rect(aes(xmin=as.Date("2021-01-27", "%Y-%m-%d"), xmax=as.Date("2021-06-30", "%Y-%m-%d"), ymin=-Inf, ymax=Inf, fill="#6DBCC3"), 
              color = alpha("#6DBCC3", .01) , 
              fill = alpha("#6DBCC3", .01)) +
    geom_rect(aes(xmin=as.Date("2021-11-24", "%Y-%m-%d"), xmax=as.Date("2022-03-19", "%Y-%m-%d"), ymin=-Inf, ymax=Inf, fill="#6DBCC3"), 
              color = alpha("#6DBCC3", .01) , 
              fill = alpha("#6DBCC3", .01)) +
    geom_hline(yintercept = 0) +
    geom_vline(xintercept = as.numeric(as.Date("2020-03-22")), size = 1, color="red") +
    geom_errorbar(aes(ymin= estimate - 1.645*std.error , ymax=estimate + 1.645*std.error),position=pd) +
    geom_point(position=pd, size=3) +
    ylab("monthly change in mobility associated with digitalisation") +
    xlab("time") +
    labs(color='digitalisation')  +
    theme_bw() +
    geom_line(position=pd) +
    facet_wrap(vars(model_name), ncol=2, labeller =  as_labeller(label_names)) +
    theme(legend.position="bottom", 
          text=element_text(size=14,  family="serif"),
          strip.text = element_text(size = 14),
          legend.text=element_text(size=14)) # +
  
  #Figure S4: Monthly decrease in mobility associated with digitalisation observed in 2022.
  ggsave("./Figures/relationship_over_time_estimated_2022_dp.png", coef,
         width = 297, height = 150, unit = "mm") 
  
  
  

form_list <- list( 
    "a" = Mobility ~ WI_19 + ags5 + week_factor + week_factor:WI_19,
    "b" = as.formula(
      str_c("Mobility ~ ags5 + ", str_c(str_c(vars_did, "week_factor", sep="*"), collapse="+"))
    )
  )
  
  df <- df %>% 
    mutate(week_factor = relevel(as.factor(week), ref = "7")) %>% 
    arrange(date)
  
  model_list <- purrr::map(form_list, function(form){
    lm_robust(formula=form, data=df %>% filter(day > 20200106 & day < 20200504), cluster=ags5,  se_type = 'stata',  weights= kr_ew_20)
  })
  
  sum <- model_list %>% 
    map_dfr(broom::tidy, .id="model_name") %>% 
    as_tibble()%>% 
    filter(str_detect(term, "week_factor" ))  %>% 
    filter(str_detect(term, "WI_" )) %>% 
    mutate(week= str_sub(term, start= 18)) %>%  
    left_join(df %>% 
                select(week, date) %>% 
                mutate(week = as.character(week)), by = "week") %>% 
    arrange(date) %>% 
    distinct( week, model_name, .keep_all = TRUE)
  
  
  
  pd <- position_dodge(width=5)
  
  coef <- sum  %>% 
    ggplot(aes(x=date, y=estimate, colour=model_name)) + 
    geom_line(position=pd) +
    geom_errorbar(aes(ymin= estimate - 1.645*std.error , ymax=estimate + 1.645*std.error),position=pd) +
    geom_point(position=pd, size=3) +
    geom_rect(aes(xmin=as.Date("2020-03-22", "%Y-%m-%d"), xmax=as.Date("2020-05-04", "%Y-%m-%d"), ymin=-Inf, ymax=Inf, fill="grey" ),
              color = alpha("grey", .01) , 
              fill = alpha("grey", .01)) +
  
    # geom_rect(aes(xmin=as.Date("2022-08-01", "%Y-%m-%d"), xmax=as.Date("2022-08-31", "%Y-%m-%d"), ymin=-Inf, ymax=Inf), 
    #           color = alpha("yellow", .005) , 
    #           fill = alpha("yellow", .005)) +
    #geom_smooth(aes(y=M_mean), method = 'gam', formula = y ~ s(x, k = 20, bs = "cs"), se=FALSE) +
    geom_hline(yintercept = 0) +
    geom_vline(xintercept = as.numeric(as.Date("2020-03-22")), size = 1, color="red") + 
    geom_vline(xintercept = as.numeric(as.Date("2020-02-17")), size = 0.5, color="grey") + 
    #theme_ipsum() +
    ylab("weekly change in mobility associated with digitalisation") +
    xlab("time") +
    scale_color_discrete(name = "model", 
                         labels = c("only digitalisation interacted with time dummies", 
                                    "digitalisation and control variables interacted with time dummies")) +
    labs(color='digitalisation')  +
    theme_bw() +
    theme(legend.position="bottom", 
          text=element_text(size=14,  family="serif"),
          strip.text = element_text(size = 14),
          legend.text=element_text(size=14)) # +
          
  

  # Figure S3: Analysis of parallel trends before the Covid-19 pandemic. 
  ggsave("./Figures/parallel_trends_2_dp.png", coef,
         width = 297, height = 150, unit = "mm")
  
  

phase_names = c(
  '0' = "pre-pandemic", 
  '1' = "1st lockdown",
  '2' = "1st open period", 
  '3' = "2nd lockd./ 1st WfH o." ,
  '4' = "2nd open period" ,
  '5' = "2nd WfH obligation" ,
  '6' = "post-pandemic" 
)


df_help <- df %>%
  pivot_longer(
    cols = starts_with("q5"),
    names_to = "indicator",
    names_prefix = "q5",
    values_to = "quintile",
    values_drop_na = TRUE
  )

df_help <- df_help%>% arrange(month)


bar_plot <-  df_help %>% 
  drop_na(phase)%>% 
  ggplot( aes(x=quintile, y=Mobility, fill=indicator)) +
  geom_bar(position = "dodge", stat = "summary") +
  facet_wrap(vars(phase), ncol=7, labeller = as_labeller(phase_names)) +
  scale_fill_grey(start = .8, end = .2, labels = c("WfH potential", "digitalisation 2020", "digitalisation 2022")) +
  theme_bw() +
  theme(aspect.ratio=1,legend.position="bottom", text=element_text(size= 14, family="serif"))  +
  ylab("change in mobility") 
  

#Figure S2: Comparison between quintiles of the WfH potential derived by Alipour et al. (2021) and the web-based
#digitalisation indicator with respect to differences in average mobility.
ggsave("./Figures/quintiles.png", bar_plot,
       width = 297, height = 210, unit = "mm")


distance <- read.csv(file = './Data/raw/mobilitaet_reisedistanz.csv'
                     , sep=";",dec = ",")

colnames(distance)[1] <- "day"

distance <- distance %>% mutate(date = ymd(day)) %>% 
  pivot_longer(
    cols = c("below.5.km", "X5.to.10.km","X10.to.30.km","X30.to.100.km","X100.km.or.above"),
    names_to = "distance",
    values_to = "change",
  ) 

d_names <- c(
  '1'="below.5.km",
  '2'="X5.to.10.km",
  '3'="X10.to.30.km",
  '4'="X30.to.100.km",
  '5'="X100.km.or.above"
)




distance_figure <-   distance %>% 
  arrange(date) %>% 
  ggplot( aes(x=date, y=change, color = distance)) +
  geom_line( size = 0.7) +
  geom_rect(aes(xmin=as.Date("2020-03-22", "%Y-%m-%d"), xmax=as.Date("2020-05-04", "%Y-%m-%d"), ymin=-Inf, ymax=Inf, fill="grey" ),
            color = alpha("grey", .01) , 
            fill = alpha("grey", .01)) +
  geom_rect(aes(xmin=as.Date("2020-11-02", "%Y-%m-%d"), xmax=as.Date("2021-01-26", "%Y-%m-%d"), ymin=-Inf, ymax=Inf,  fill="grey"), 
            color = alpha("grey", .01) , 
            fill = alpha("grey", .01)) +
  geom_rect(aes(xmin=as.Date("2021-01-27", "%Y-%m-%d"), xmax=as.Date("2021-06-30", "%Y-%m-%d"), ymin=-Inf, ymax=Inf, fill="#6DBCC3"), 
            color = alpha("#6DBCC3", .01) , 
            fill = alpha("#6DBCC3", .01)) +
  geom_rect(aes(xmin=as.Date("2021-11-24", "%Y-%m-%d"), xmax=as.Date("2022-03-19", "%Y-%m-%d"), ymin=-Inf, ymax=Inf, fill="#6DBCC3"), 
            color = alpha("#6DBCC3", .01) , 
            fill = alpha("#6DBCC3", .01)) +  geom_hline(yintercept = 0) +
  geom_vline(xintercept = as.numeric(as.Date("2020-03-22")), size = 1, color="red") + 
  #theme_ipsum() +
  ylab("monthly change in mobility ") +
  xlab("time") +
  scale_color_brewer(palette = "Set2",
                     name = "distance", 
                     breaks= d_names,
                     labels = c( "below 5 km", "5 to below 10 km",
                                 "10 to below 30 km","30 to below 100 km","100 km or above")) +
  theme_bw() +
  theme(legend.position="bottom", text=element_text(size=10,  family="serif"))  



#Figure S1: Change in mobility compared to 2019 by distance in % (7-day average). The red
ggsave("./Figures/distance_figure_dp.png", distance_figure,
       width = 297, height = 150, unit = "mm")



