#!/bin/bash
#
#Estrazione delle stazioni elencate nel form della pagina:
# http://centrofunzionale.regione.campania.it/#/pages/sensori/archivio-termo
#
#Fare lo scraping di questa pagina non conviene, in quanto ci sono diversi contenitori che contengono io documento vero e proprio che e'
#il form per lo scarico dele stazioni. Utilizzando web-inspector si trova il link:
# http://centrofunzionale.regione.campania.it/regionecampania/centrofunzionale/archiviosensori/termo.php
#
# Questo link e' quello che genera il forma. Quindi: apriamo il secondo link e salviamo la pagina html. In questa pagina compare il campo
#form con le varie "option" ovvero l'elenco dei sensori. Quest elenco invece non compare se si utilizza il primo link riportato.

#Mediante sed e grep e' possibile tirare fuori una lista delle stazioni/sensori termo.


grep -E "<option" Valori\ Pluviometrici.html  \
| sed -e 's/<\/option>/\n/g' \
| sed -e 's/>/,/g' \
| sed -e 's/^<option.\+="//g' \
| sed -e 's/"//g' > sensoriPrecipitazione.csv

