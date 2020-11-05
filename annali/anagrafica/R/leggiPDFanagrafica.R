rm(list=objects())
library("pdftools")
library("tidyverse")

pdf_text("Coordinate_annali_campania.pdf")->ana
str_replace_all(ana," ([0-9])",";\\1")->ana
sink("ana.csv")
cat(ana)
sink()