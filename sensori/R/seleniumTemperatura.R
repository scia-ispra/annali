rm(list=objects())
library("RSelenium")
library("tidyverse")
library("rvest")
library("read.so")
ANNI<-2020:2020

"http://centrofunzionale.regione.campania.it/regionecampania/centrofunzionale/archiviosensori/termo.php"->myurl

try(dir.create("Tmax"))
try(dir.create("Tmin"))

calendario<-tibble(yymmdd=seq.Date(from=as.Date("2000-01-01"),to=as.Date("2020-12-31"),by="day")) %>%
  separate(yymmdd,into=c("yy","mm","dd"),sep="-") %>%
  dplyr::select(yy,mm,dd)

RSelenium::rsDriver(port =4569L,version = "3.141.59",verbose=TRUE, browser = c("firefox"),check=F)->mydrv
mydrv[["client"]]->remDr
remDr$navigate(myurl)

read_md("sensori.md")->sensori

purrr::walk(sensori$idSensoreTemp,.f=function(.id){

remDr$findElement("id","select_sensore")
xpathSensore<-glue::glue("//*/option[@value = '{.id}']")
remDr$findElement(using="xpath",xpathSensore)$clickElement()
remDr$findElement("id","select_anno")

    purrr::map(ANNI,.f=function(.anno){
      
        xpathAnno<-glue::glue("//*/option[@value = '{.anno}']")
        Sys.sleep(2)
        try(remDr$findElement(using="xpath",xpathAnno))->resultTry
        
        if(class(resultTry)=="try-error"){
          return()
        }else{
          resultTry$clickElement()
        }

        remDr$findElement("tag name","input")$clickElement()
        Sys.sleep(2)
        remDr$getPageSource()[[1]]->html
        
        read_html(html) %>%
          html_nodes("table") %>%
          .[2] %>%
          .[[1]] %>%
          html_table(fill=TRUE)->tabella
        
        names(tabella)<-c("Data",glue::glue("Tmax.{.id}"),glue::glue("Tmean.{.id}"),glue::glue("Tmin.{.id}"),"flag")
        tabella %>%
          mutate(Data=as.Date(Data,"%d/%m/%Y")) %>%
          separate(Data,into=c("yy","mm","dd"),sep="-") %>%
          dplyr::select(yy,mm,dd,matches("^Tm.+")) %>%
          mutate(across(.cols=matches("^Tm.+",ignore.case = FALSE),.fns = as.double))->tabella2

        remDr$findElement(using="xpath","//input[@value='Nuova Estrazione']")$clickElement()
        
        tabella2
        
    })->listaTabelle
    
    purrr::compact(listaTabelle)->listaTabelle
    
    if(!length(listaTabelle)) return()
    
    reduce(listaTabelle,.f=bind_rows) %>%
      arrange(yy,mm,dd)->df
    
    full_join(calendario,df)->df
    
    write_delim(df %>%dplyr::select(yy,mm,dd,matches("Tmax.+")),file=glue::glue("./Tmax/{.id}.csv"),delim=";",col_names=TRUE)
    write_delim(df %>%dplyr::select(yy,mm,dd,matches("Tmin.+")),file=glue::glue("./Tmin/{.id}.csv"),delim=";",col_names=TRUE)
    
}) #su sensore