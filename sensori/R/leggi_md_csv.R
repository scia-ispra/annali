rm(list=objects())
library("tidyverse")
# install.packages("remotes")
# remotes::install_github("alistaire47/read.so") legge tabelle in formato pipe
library("read.so")

read_delim("sensoriPrecipitazione.csv",delim=",",col_names = TRUE)->prec
read_md("sensoriTemperatura.md")->temp

full_join(prec,temp)->finale
write_delim(finale %>% dplyr::select(nome,everything()),"sensori.csv",delim=",",col_names = TRUE)