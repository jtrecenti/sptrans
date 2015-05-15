# -----------------------------------------------------------------------------
# DEPRECATED.
# Essas funcoes serao utilizadas no futuro para montar a nova "API" do pacote.
# -----------------------------------------------------------------------------

olhovivo_pega_posicao <- function(cod_linha_olhovivo) {
  u <- url_base()
  u_busca_posicoes <- paste0(u, '/Posicao?codigoLinha=', cod_linha_olhovivo)
  r_busca_posicoes <- httr::GET(u_busca_posicoes)
  l_busca_posicoes <- jsonlite::fromJSON(httr::content(r_busca_posicoes, 
                                                       'text'))
  d_busca_posicoes <- l_busca_posicoes$vs
  if(!is.data.frame(d_busca_posicoes)) {
    return(data.frame())
  }
  return(d_busca_posicoes)
}

olhovivo_pega_posicoes_linha <- function(cod_linha) {
  d_busca_linhas <- olhovivo_pega_linha(cod_linha)
  d_busca_linhas_gr <- dplyr::group_by_(d_busca_linhas, 
                                        .dots = names(d_busca_linhas))
  d_posicoes <- dplyr::do(d_busca_linhas_gr, 
                          olhovivo_pega_posicao(.$CodigoLinha))
  d_posicoes <- dplyr::ungroup(d_posicoes)
  return(d_posicoes)
}

olhovivo_pega_posicoes_linhas <- function(cod_linhas) {
  cod_linhas <- unique(cod_linhas)
  if(length(cod_linhas) > 10) {
    stop('No maximo 10 linhas diferentes')
  }
  d <- dplyr::data_frame(linha = cod_linhas, color = 0:(length(cod_linhas) - 1))
  d <- dplyr::group_by(d, linha, color)
  d <- dplyr::do(d, olhovivo_pega_posicoes_linha(.$linha))
  d <- dplyr::ungroup(d)
  d
}

# -----------------------------------------------------------------------------

olhovivo_pega_linha <- function(cod_linha) {
  u <- url_base()
  u_busca_linhas <- paste0(u, '/Linha/Buscar?termosBusca=', cod_linha)
  r_busca_linhas <- httr::GET(u_busca_linhas)
  d_busca_linhas <- jsonlite::fromJSON(httr::content(r_busca_linhas, 'text'))
  d_busca_linhas
}


olhovivo_pega_linhas <- function(cod_linhas) {
  d <- dplyr::data_frame(linha = cod_linhas)
  d <- dplyr::group_by(d, linha)
  d <- dplyr::do(d, olhovivo_pega_linha(.$linha))
  d <- dplyr::ungroup(d)
  d
}

olhovivo_pega_paradas <- function(query) {
  u <- url_base()
  dados <- sprintf('/Parada/Buscar?termosBusca=%s', URLencode(query))
  u_busca_parada <- paste0(u, dados)
  r_busca_parada <- httr::GET(u_busca_parada)
  d_busca_parada <- jsonlite::fromJSON(httr::content(r_busca_parada, 'text'))
  d_busca_parada
}

# -----------------------------------------------------------------------------

olhovivo_pega_previsao_linhas_paradas <- function(cod_linhas, cod_paradas) {
  linhas_olhovivo <- olhovivo_pega_linhas(cod_linhas)
  comb <- expand.grid(
    CodigoLinha = unique(linhas_olhovivo$CodigoLinha), 
    stop_id = unique(as.numeric(cod_paradas)),
    stringsAsFactors = FALSE
  )
  comb <- dplyr::inner_join(comb, linhas_olhovivo, c('CodigoLinha'))
  comb <- dplyr::mutate(comb, direction = as.numeric(Sentido) - 1)
  comb <- tidyr::unite(comb, trip_id, Letreiro, Tipo, direction, sep = '-', 
                       remove = F)
  # verifica na base stop_times se existe a combinacao
  comb <- dplyr::semi_join(comb, stop_times, c('trip_id', 'stop_id'))
  comb <- dplyr::group_by_(comb, .dots = names(comb))
  d <- dplyr::do(comb, olhovivo_pega_previsao_linha_parada(.$CodigoLinha, 
                                                           .$stop_id))
  d <- dplyr::ungroup(d)
  d
}

olhovivo_pega_previsao_linha_parada <- function(cod_linha, cod_parada) {
  cod_linha <- as.character(cod_linha)
  cod_parada <- as.character(cod_parada)
  u <- url_base()
  dados <- sprintf('/Previsao?codigoParada=%s&codigoLinha=%s', 
                   cod_parada, cod_linha)
  u_busca_linha_parada <- paste0(u, dados)
  r_busca_linha_parada <- httr::GET(u_busca_linha_parada)
  d_busca_linha_parada <- jsonlite::fromJSON(httr::content(r_busca_linha_parada, 
                                                           'text'))
  if(is.null(d_busca_linha_parada$p)) return(data.frame())
  d_prev <- d_busca_linha_parada$p$l$vs[[1]]
  d_prev
}

# -----------------------------------------------------------------------------

leaflet_mapeia_linhas <- function(cod_linhas, sentido = NULL, m = NULL) {
  d <- olhovivo_pega_posicoes_linhas(cod_linhas)
  
  if(!is.null(sentido)) {
    d0 <- dplyr::data_frame(cod_linhas, sentido = sentido + 1)
    d <- dplyr::inner_join(d, d0, c('linha' = 'cod_linhas', 
                                    'Sentido' = 'sentido'))
  }
  
  if(is.null(m)) {
    m <- leaflet::addTiles(leaflet::leaflet())
  }
  m <- leaflet::fitBounds(m, min(d$px), min(d$py), max(d$px), max(d$py))
  for(i in unique(d$color)) {
    d_filter <- dplyr::filter(d, color == i)
    d_filter <- dplyr::mutate(
      d_filter, label = paste0(linha, '<br/>', 
                        ifelse(Sentido == 1, DenominacaoTPTS, DenominacaoTSTP))
    )
    
    m <- leaflet::addMarkers(m, lng = ~px, lat = ~ py, 
                             icon = pega_bus(i), 
                             data = dplyr::filter(d, color == i), 
                             popup = htmltools::HTML(unique(d_filter$label)))
  }
  m
}

#' Desenha as shapes das linhas de onibus no mapa nao usa API
#' 
#' @import spgtfs
leaflet_desenha_shapes <- function(cod_linhas = NULL, 
                                   shape_ids = NULL, m = NULL) {
  if(!is.null(cod_linhas) & is.null(shape_ids)) {
    # pega ida e volta
    shape_ids <- dplyr::filter(trips, route_id %in% cod_linhas)
    shape_ids <- unique(shape_ids$shape_id)
  }
  if(is.null(m)) {
    m <- leaflet::addTiles(leaflet::leaflet())
  }
  s0 <- dplyr::filter(shapes, shape_id %in% shape_ids)
  m <- leaflet::fitBounds(m, min(s0$shape_pt_lon), 
                          min(s0$shape_pt_lat), 
                          max(s0$shape_pt_lon), 
                          max(s0$shape_pt_lat))
  for(s in shape_ids) {
    co <- substr(rainbow(length(shape_ids), v = .8)[s == shape_ids], 1, 7)
    shapes_filter <- dplyr::filter(shapes, shape_id %in% s)
    m <- leaflet::addPolylines(m, lat = ~ shape_pt_lat, lng = ~ shape_pt_lon,
                               data = shapes_filter, 
                               smoothFactor = 1.2, 
                               opacity = .8, 
                               color = co, 
                               fillColor = NULL, 
                               weight = 2)
  }
  m
}

leaflet_fit_bounds_rad <- function(m, lng, lat, zoom, r) {
  m <- leaflet::setView(m, lng, lat, zoom)
  m <- leaflet::addCircles(m, lng, lat, radius = r)
  m
}

#' Desenha as paradas
leaflet_stops <- function(stop_ids = NULL) {
  leaflet_fit_bounds_rad
  m
}

