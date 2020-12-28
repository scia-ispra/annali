#Unisce i file scaricati dalla regione Campania e sostituisce il codice sensore con il SiteID
#Il file di output ha il formato giusto per i controlli di qualita'
rm(list=objects())
library("tidyverse")
library("seplyr")

PARAM<-c("Tmax","Tmin","Prec")[3]

if(grepl("Tm",PARAM)){
  colonnaSensore<-"idSensoreTemp"
}else{
  colonnaSensore<-"idSensorePrec"
}

read_delim("reg.campania.sensori.info.csv",delim=";",col_names = TRUE)->ana

ana %>%
  seplyr::rename_se(c("idSensore":=colonnaSensore)) %>%
  mutate(idSensore=as.integer(idSensore))->ana

list.files(pattern="^[0-9]+\\.csv$")->ffile

purrr::map(ffile,.f=function(nomeFile){
  
  as.integer(str_extract(nomeFile,"^[0-9]+"))->codice
  which(ana$idSensore==codice)->riga
  if(length(riga)!=1) stop("Codice non trovato, impossibile")

  ana[riga,]$SiteID->siteid
  
  read_delim(nomeFile,delim=";",col_names = TRUE,col_types = cols(yy=col_integer(),mm=col_integer(),dd=col_integer(),.default = col_double()))->dati
 
  names(dati)[4]<-siteid
  
  dati
  
}) %>% purrr::reduce(.,.f=full_join)->finale

finale %>%
  arrange(yy,mm,dd) %>%
  write_delim(.,glue::glue("{PARAM}_sensori.csv"),delim=";",col_names=TRUE)
