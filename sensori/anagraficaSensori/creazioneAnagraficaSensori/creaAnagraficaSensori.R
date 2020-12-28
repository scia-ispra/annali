rm(list=objects())
library("tidyverse")
library("fuzzyjoin")
library("DataEditR")
library("raster")
library("sf")
library("sp")

read_delim("anaSensoriPrecipitazione.csv",delim=";",col_names = TRUE) %>%
  dplyr::select(-quota) %>%
  rename(idSensorePrec=idSensore) %>%
  mutate(nome=Hmisc::capitalize(tolower(str_trim(nome,side="both"))))->anaPrec

read_delim("anaSensoriTemperatura.csv",delim=";",col_names = TRUE) %>%
  dplyr::select(-quota) %>%
  rename(idSensoreTemp=idSensore)%>%
  mutate(nome=Hmisc::capitalize(tolower(str_trim(nome,side="both")))) %>%
  mutate(nome2=str_remove(nome,"termo"))->anaTemp

fuzzyjoin::stringdist_join(anaPrec,anaTemp,by=c("nome"="nome2"),mode="full",max_dist=1,distance_col="distanza")->anaString
#fuzzyjoin::geo_join(anaPrec %>% dplyr::select(-nome),anaTemp%>% dplyr::select(-nome,-nome2),max_dist=0.1,unit="km",distance_col="distanzakm")->anaDist

#left_join(anaPrec %>% dplyr::select(nome,idSensorePrec),anaDist)->anaDist
#left_join(anaTemp %>% dplyr::select(nome2,idSensoreTemp),anaDist)->anaDist

# DataEditR::data_edit(anaDist,viewer = FALSE,
#                      save_as="anaDist.csv",
#                      write_fun = readr::write_delim,
#                      write_args = list(delim=";",col_names=TRUE))

#anaDist.csv l'ho ottenuto mediante il geo_join, poi l'ho elaborato mediante DataEditR eliminando
#associazioni tipo Agerola Meteo 2 con Agerola Meteo 1 e lasciando solo: Agerola Meteo 1 con Agerola Meteo 1
read_delim("anaDist.csv",delim=";",col_names = TRUE) %>%
  dplyr::select(-matches(".+\\.y$")) %>%
  rename(latitudine=latitudine.x,longitudine=longitudine.x) %>%
  rename(nomePrec=nome,nomeTemp=nome2)->anaDist



#togliamo ad anaString le associazioni che distavano meno di 100 metri. Cosa rimane?
#Rimangono solo 102 stazioni della precipitazione che NON sono riuscito ad associare utilizzando
#i nomi delle stazioni (in quanto nomi troppo differenti tra temperatura e precipitazione)
which(anaString$idSensorePrec %in% anaDist$idSensorePrec)->righe

#daAggiungere contiene le 102 stazioni della precipitazione che non sono presenti nella temperatura
#anaDist contiene 98 stazioni che sono le 98 stazioni in comune fra temperatura e precipitazione.
#Le stazioni di temperatura sono esattamente 98, quello che rimane sono le stazioni "in eccesso" della precipitazione
anaString[-righe,]->daAggiungere

daAggiungere %>%
  rename(latitudine=latitudine.x,longitudine=longitudine.x) %>%
  rename(nomePrec=nome.x) %>%
  dplyr::select(idSensorePrec,nomePrec,latitudine,longitudine)->daAggiungere

bind_rows(anaDist,daAggiungere)->finale

finale$SiteID<-1:nrow(finale)

finale %>%
  mutate(SiteName=nomePrec) %>%
  mutate(SiteCode=NA) %>%
  rename(Latitude=latitudine,Longitude=longitudine)->finale

raster("q_dem.tif")->dem
st_as_sf(finale,coords=c("Longitude","Latitude"),crs=4326)->sfFinale
st_transform(sfFinale,crs=32632)->sfFinale
as_Spatial(sfFinale)->spFinale
raster::extract(x = dem,y=spFinale)->altezza
spFinale$Elevation_dem<-altezza
as.data.frame(spFinale)->finale

finale %>%
  rename(Longitude=coords.x1,Latitude=coords.x2) %>%
  rename(distanzakm_sensoreTemp_sensorePrec=distanzakm) %>%
  dplyr::select(SiteID,SiteCode,SiteName,Longitude,Latitude,Elevation_dem,everything())->finale


write_delim(finale,"reg.campania.sensori.info.csv",delim=";",col_names = TRUE)