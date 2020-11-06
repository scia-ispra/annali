rm(list=objects())
library("tidyverse")
library("sf")
library("sp")

read_delim("anagrafica_annali_epsg4326.csv",delim=";",col_names = TRUE)->annali
read_delim("anaSensoriTemperatura.csv",delim=";",col_names = TRUE)->sensori

coordinates(annali)=~lon+lat 
proj4string(annali)<-CRS("+init=epsg:4326")
spTransform(annali,CRS("+init=epsg:32632"))->annali

coordinates(sensori)=~longitudine+latitudine 
proj4string(sensori)<-CRS("+init=epsg:4326")
spTransform(sensori,CRS("+init=epsg:32632"))->sensori

sp::spDists(annali,sensori)->distanze

as.data.frame(distanze)->distanze
names(distanze)<-sensori$nome
distanze$annali<-annali$Stazione

distanze %>%
  gather(key="sensori",value="distanze",-annali)->