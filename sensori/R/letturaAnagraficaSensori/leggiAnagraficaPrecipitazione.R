rm(list=objects())
library("RJSONIO")
library("tidyverse")
library("read.so")

read_md("ana.md")->ana
filter(ana,!is.na(idPrecipitazione))->ana

purrr::map(ana$idPrecipitazione,.f=function(.id){

 print(.id)
  glue::glue("http://centrofunzionale.regione.campania.it/CentroFunzionalePortaleRest/rest/utils/getPluviometroById/{.id}")->stringaSensore
  
  tryCatch({
    fromJSON(stringaSensore)
  },error=function(e){
    NULL
  })->dati
  
  if(is.null(dati)){
    
    sink("log.txt",append = TRUE)
    cat(paste0(.id,"\n"))
    sink()

    return()

  }


  dati$sensoriBean->dati

  pluck(dati,"idSensore")->.id2
  stopifnot(.id==.id2)

  #ifelse(is.null(quota),-999,quota)->quota

  tibble(idSensore=.id,
         nome=pluck(dati,"nome"),
         latitudine=pluck(dati,4),
         longitudine=pluck(dati,5),
         quota=-999)->df

  Sys.sleep(5)

  df


})->listaOut

purrr::compact(listaOut)->listaOut2

if(length(listaOut2)){

  purrr::reduce(listaOut2,.f=bind_rows)->finale
  write_delim(finale,"anaSensoriPrecipitazione.csv",delim=";",col_names = TRUE) #fine map_df

}