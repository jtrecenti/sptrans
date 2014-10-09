library(abjutils)
source('leaflet.R')
library(httr)
library(jsonlite)

# Banco de dados com todas as linhas da SPTrans
load("bd/linhas.rds")

# URL do API do SPTrans
url_sptrans <- "http://api.olhovivo.sptrans.com.br/v0/"

# Token do seu aplicativo (gerado no site da SPTrans. Precisa fazer uma conta!)
token = "2a5270e018715de6b750cba0b77dd08868f2ba4989be5e8e49a5e8ddb9b8e4b2"

# POST de autenticação para pegar infos do API
POST(url = paste0("http://api.olhovivo.sptrans.com.br/v0/Login/Autenticar?token=", token), body = "")


