url_base <- function() {
  u <- 'http://api.olhovivo.sptrans.com.br/v0'
  u
}

#' @export
olhovivo_login <- function(token = NULL) {
  if(is.null(token)) {
    token <- '233f343e2ad2a3bf483eae00c316cfdd516c3bbbd21b6a3e916645877e137b6f'
  }
  u <- url_base()
  u_login <- paste0(u, '/Login/Autenticar?token=', token)
  r <- httr::POST(u_login)
  result <-httr::content(r, 'text')
  if(result == 'true') {
    cat('Login realizado com sucesso!\n')
    return(r)
  } else {
    stop('Ocorreu um erro ao acessar a API da SPTrans.')
  }
}

olhovivo_pega_posicao <- function(cod_linha_olhovivo) {
  u <- url_base()
  u_busca_posicoes <- paste0(u, '/Posicao?codigoLinha=', cod_linha_olhovivo)
  r_busca_posicoes <- httr::GET(u_busca_posicoes)
  l_busca_posicoes <- jsonlite::fromJSON(httr::content(r_busca_posicoes, 'text'))
  d_busca_posicoes <- l_busca_posicoes$vs
  return(d_busca_posicoes)
}

#' @export
olhovivo_pega_posicoes_linha <- function(cod_linha) {
  u <- url_base()
  u_busca_linhas <- paste0(u, '/Linha/Buscar?termosBusca=', cod_linha)
  r_busca_linhas <- httr::GET(u_busca_linhas)
  d_busca_linhas <- jsonlite::fromJSON(httr::content(r_busca_linhas, 'text'))
  print(d_busca_linhas)
  cod_linha_olhovivo <- d_busca_linhas$CodigoLinha[1]
  d_busca_linhas_gr <- dplyr::group_by_(d_busca_linhas, .dots = names(d_busca_linhas))
  d_posicoes <- dplyr::do(d_busca_linhas_gr, olhovivo_pega_posicao(.$CodigoLinha))
  d_posicoes <- dplyr::ungroup(d_posicoes)
  return(d_posicoes)
}

#' @export
olhovivo_pega_posicoes_linhas <- function(cod_linhas) {
  cod_linhas <- unique(cod_linhas)
  if(length(cod_linhas) > 10) {
    stop('No maximo 10 linhas diferentes')
  }
  d <- dplyr::data_frame(linha = cod_linhas, colour = '')
  d <- dplyr::bind_rows(lapply(cod_linhas, olhovivo_pega_posicoes_linha))
  d
}

pega_bus <- function(color) {
  base <- 'https://github.com/jtrecenti/sptrans/blob/tree/master/inst'
  l <- sprintf('%s/icons/%d-bus.png')
  js <- invisible(JS(sprintf("L.icon({ iconUrl: '%s', iconSize: [32, 37] })", path)))
  js
}

#' @export
leaflet_mapeia_linhas <- function(cod_linhas, m = NULL) {
  d <- olhovivo_pega_posicoes_linhas(cod_linhas)
  if(is.null(m)) {
    m <- leaflet::addTiles(leaflet::leaflet(d))
  }
  m <- leaflet::fitBounds(m, min(d$px), min(d$py), max(d$px), max(d$py))
  m <- leaflet::addMarkers(m, lng = ~px, lat = ~ py, icon = pega_bus(3))
  m
}

