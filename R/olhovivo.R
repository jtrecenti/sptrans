url_base <- function() {
  u <- 'http://api.olhovivo.sptrans.com.br/v0'
  u
}

olhovivo_GET <- function(path, id, pat = olhovivo_pat()) {
  u <- url_base()
  u_busca <- paste0(u, path, id)
  req <- httr::GET(u_busca)
  if(req$status_code == 401) {
    olhovivo_auth()
    req <- httr::GET(u_busca)
  }
  req
}

olhovivo_auth <- function(pat = olhovivo_pat()) {
  u <- url_base()
  u_login <- paste0(u, '/Login/Autenticar?token=', pat)
  r <- httr::POST(u_login)
  result <- httr::content(r, 'text')
  if(result == 'true') {
    cat('Autenticação realizada com sucesso!\n')
    return(invisible(r))
  } else {
    stop('Ocorreu um erro ao acessar a API da SPTrans.')
  }
}

# -----------------------------------------------------------------------------

olhovivo_pat <- function(force = FALSE) {
  env <- Sys.getenv('OLHOVIVO_PAT')
  if (!identical(env, "") && !force) return(env)
  
  if (!interactive()) {
    stop("Insira uma env var OLHOVIVO_PAT para acessar a API",
         call. = FALSE)
  }
  message("Nao achei a env var OLHOVIVO_PAT.")
  message("Insira seu PAT e pressione enter:")
  pat <- readline(": ")
  if (identical(pat, "")) {
    stop("Falhou :(", call. = FALSE)
  }
  message("Atualizando OLHOVIVO_PAT env var para PAT")
  Sys.setenv(olhovivo_PAT = pat)
  pat
}

# -----------------------------------------------------------------------------
# a partir de codigos do olhovivo

collect_bus_trip <- function(CodigoLinha) {
  r <- olhovivo_GET('/Posicao?codigoLinha=', CodigoLinha)
  l_posicoes <- jsonlite::fromJSON(httr::content(r, 'text'))
  d_posicoes <- l_posicoes$vs
  if(!is.data.frame(d_posicoes)) {
    return(data.frame())
  }
  return(d_posicoes)
}

collect_bus_trips <- function(ids, collect) {
  d_linhas <- collect(ids)
  CodigosLinhas <- d_linhas$CodigoLinha
  d <- dplyr::data_frame(CodigoLinha = CodigosLinhas) %>%
    dplyr::group_by(CodigoLinha) %>%
    dplyr::do(collect_bus_trip(.$CodigoLinha)) %>%
    dplyr::ungroup() %>%
    dplyr::inner_join(d_linhas, 'CodigoLinha')
  d
}

# -----------------------------------------------------------------------------

# a partir de codigos do gtfs
collect_route <- function(route_id) {
  r <- olhovivo_GET('/Linha/Buscar?termosBusca=', route_id)
  d_busca_linhas <- jsonlite::fromJSON(httr::content(r, 'text'))
  d_busca_linhas
}

collect_routes <- function(route_ids) {
  d <- dplyr::data_frame(route_id = unique(route_ids)) %>%
    dplyr::group_by(route_id) %>%
    dplyr::do(collect_route(.$route_id)) %>%
    dplyr::ungroup()
  d
}

collect_trips <- function(trip_ids) {
  route_ids <- gsub('-[0-9]$', '', unique(trip_ids))
  d_routes <- collect_routes(route_ids)
  d_trips <- d_routes %>%
    dplyr::mutate(trip_id = sprintf('%s-%d', route_id, Sentido-1)) %>%
    dplyr::filter(trip_id %in% trip_ids)
  d_trips
}

# -----------------------------------------------------------------------------

#' Coleta dados das posições de ônibus
#'
#' Coleta dados a partir de ids informados e do tipo de ids, podendo ser
#' ids de linhas ou rotas. Pesquisa no máximo 8 trips ou rotas de uma vez.
#'
#' @param .data dados (geralmente coletados) 
#'   pela função \code{\link{search_path}}.
#' @param ids nome da coluna que tem os ids que desejamos pesquisar,
#'   geralmente \code{route_id} ou \code{trip_id}
#' @param type tipo de pesquisa, podendo ser "trip" ou "route"
#'
#' @export
#' 
#' @examples
#' trip_ids <- search_path(
#'   end1 = 'Avenida 9 de Julho, 2000, São Paulo', 
#'   end2 = 'Av. Pres. Juscelino Kubitschek, 500, São Paulo'
#' )
#' 
#' stop_ids <- nearby_stops('Avenida Paulista, 1079, São Paulo')
#' 
#' trip_ids %>% collect_bus(trip_id, 'trip')
#' trip_ids %>% collect_bus(route_id, 'route')
#'
collect_bus <- function(.data, ids, type = c('trip', 'route')) {
  i <- eval(substitute(ids), .data, parent.frame())
  if(length(type) != 1) {
    stop("Por favor selecione type entre 'trip' e 'route'.")
  }
  if(length(unique(i)) > 8) {
    i <- unique(i)[1:8]
  } 
  if(type == 'trip') {
    res <- collect_bus_trips(i, collect_trips)
  } else if(type == 'route') {
    res <- collect_bus_trips(i, collect_routes)
  } else {
    res <- NULL
  } 
  res
}

# -----------------------------------------------------------------------------

#' Desenha ônibus em tempo real
#'
#' A partir de dados coletados da API OlhoVivo, desenha os ônibus no mapa
#' gerado pelo pacote leaflet.
#'
#' @param .data data frame retornado pela função \code{collect_bus}.
#' @param map Mapa para adicionar layes, caso já exista.
#'
#' @export
#' 
#' @examples
#' trip_ids <- search_path(
#'   end1 = 'Avenida 9 de Julho, 2000, São Paulo', 
#'   end2 = 'Av. Pres. Juscelino Kubitschek, 500, São Paulo'
#' )
#' 
#' stop_ids <- nearby_stops('Avenida Paulista, 1079, São Paulo')
#' 
#' trip_ids %>% 
#'   collect_bus(trip_id, 'trip') %>% 
#'   draw_bus()
#' 
draw_bus <- function(.data, map = NULL) {
  if(is.null(map)) {
    map <- leaflet::leaflet() %>% 
      leaflet::addTiles()
  }
  trips <- unique(.data$trip_id)
  for(i in seq_along(trips)) {
    d <- dplyr::filter(.data, trip_id == trips[i])
    map <- map %>%
      leaflet::addMarkers(~px, ~py, data = d, icon = pega_bus(i))
  }
  map
}
