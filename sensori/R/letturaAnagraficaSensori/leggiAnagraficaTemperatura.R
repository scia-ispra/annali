rm(list=objects())
library("RJSONIO")
library("tidyverse")
library("read.so")

read_md("ana.md")->ana
filter(ana,!is.na(idTemperatura))->ana

purrr::map(ana$idTemperatura,.f=function(.id){
  
  print(.id)

  glue::glue("http://centrofunzionale.regione.campania.it/CentroFunzionalePortaleRest/rest/utils/getTermometroById/{.id}")->stringaSensore
  
  tryCatch({
    fromJSON(stringaSensore)
  },error=function(e){
    NULL
  })->dati
  
  if(is.null(dati)){print("NULL"); return()}
    
  dati$sensoriBeanList[[1]]->dati

  pluck(dati,"idSensore")->.id2
  stopifnot(.id==.id2)
  
  pluck(dati,"quota")->quota
  ifelse(is.null(quota),-999,quota)->quota
  
  tibble(idSensore=.id,
         nome=pluck(dati,"nome"),
         latitudine=pluck(dati,4),
         longitudine=pluck(dati,5),
         quota=quota)->df
  
  Sys.sleep(5)

  df

})->listaOut

purrr::compact(listaOut)->listaOut2

if(length(listaOut2)){

  purrr::reduce(listaOut2,.f=bind_rows)->finale
  write_delim(finale,"anaSensoriTemperatura.csv",delim=";",col_names = TRUE) #fine map_df
  
}  