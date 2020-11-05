rm(list=objects())
library("tidyverse")
library("sf")
library("maps")
library("DataEditR")

read_delim("ana.csv",delim=";",col_names = TRUE,col_types = cols(.default =col_character()))->dati
dati %>%
  dplyr::select(1:10) %>%
  mutate(across(.cols =2:10,.fns = as.double ))->dati2
#data_edit(dati2,viewer = FALSE)
st_as_sf(dati2,coords = c("x_utm33_ed50","y_utm33_ed50"),crs=23033)->sfDati
st_transform(sfDati,crs=4326)->sfDati2
st_write(sfDati2,"campania","campania",driver = "ESRI Shapefile")
as.data.frame(st_coordinates(sfDati2))->coordinate
names(coordinate)<-c("lon","lat")
st_geometry(sfDati2)<-NULL
bind_cols(sfDati2,coordinate)->sfDati2
write_delim(sfDati2,"anagrafica_annali_epsg4326.csv",delim=";",col_names = TRUE)