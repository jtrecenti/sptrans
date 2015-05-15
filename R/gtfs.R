#' Pipe operator
#'
#' See \code{\link[magrittr]{\%>\%}} for more details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom magrittr %>%
#' @usage lhs \%>\% rhs
NULL

#' Identifica pontos de ônibus próximos
#'
#' Calcula distâncias entre um ponto escolhido e os pontos de ônibus, 
#' retornando somente aqueles que estão dentro do raio informado.
#'
#' @param end Endereço para procurar (como se estivesse pesquisando no google maps).
#' @param radius Raio em metros para procura dos pontos mais próximos. Por
#'   padrão vale 300 metros.
#' @param lon Longitude. Informar se o endereço for nulo.
#' @param lat Latitude. Informar se o endereço for nulo.
#' 
#' @return Um data frame contendo um subset de \code{stops} 
#'   (pacote \code{spgtfs}) com os pontos mais próximos, ordenados
#'   por proximidade
#' 
#' @import spgtfs
#' 
#' @export
#' @examples
#' nearby_stops('Avenida Paulista, 1079')
#' nearby_stops('Avenida Paulista, 1079', radius = 200)
#' nearby_stops(lon = -46.6527, lat = -23.5648)
nearby_stops <- function(end = NULL, radius = 300, lon = NULL, lat = NULL) {
  if(is.null(end)) {
    if(is.null(lon) | is.null(lat)) {
      stop('Especifique um endereço ou longitude/latitude.')
    }
    coord <- as.numeric(c(lon, lat))
  } else {
    coord <- as.numeric(ggmap::geocode(end))
  }
  d <- stops
  d$distance <- geodetic_distance_v(coord[1], coord[2], 
                                    stops$stop_lon, stops$stop_lat)
  d <- dplyr::filter(d, distance < radius)
  if(nrow(d) == 0) {
    stop('Nenhum ponto encontrado para o endereço e raio especificados.')
  }
  d <- dplyr::arrange(d, distance)
  d$my_lon <- coord[1]
  d$my_lat <- coord[2]
  d$radius <- radius
  d
}

# Retirado de http://www.biostat.umn.edu/~sudiptob/Software/distonearth.R
geodetic_distance <- function(lon1, lat1, lon2, lat2) {
  R <- 6378388 # peguei esse valor da função rdist.earth do pacote fields
  p1rad <- c(lat1, lon1) * pi / 180
  p2rad <- c(lat2, lon2) * pi / 180
  d <- sin(p1rad[2]) * sin(p2rad[2]) + 
    cos(p1rad[2]) * cos(p2rad[2]) * cos(abs(p1rad[1] - p2rad[1]))  
  d <- acos(d)
  R * d
}
geodetic_distance_v <- Vectorize(geodetic_distance)

#' Desenha os pontos de ônibus
#' 
#' A partir de um objeto retornado pela função \code{nearby_stops}, desenha
#' um mapa com o lugar escolhido, o raio selecionado e os pontos de ônibus
#' próximos.
#' 
#' @return Um objeto HTML widget do pacote \code{leaflet}.
#' 
#' @export 
#' @examples 
#' nearby_stops('Avenida Paulista, 1079') %>% draw_stops()
draw_stops <- function(.data) {
  d <- .data
  m <- d %>%
    leaflet::leaflet() %>% 
    leaflet::addTiles() %>% 
    leaflet::addCircles(d$my_lon[1], d$my_lat[1], d$radius[1], stroke = FALSE) %>%
    leaflet::addMarkers(d$my_lon[1], d$my_lat[1]) %>% 
    leaflet::addMarkers(~stop_lon, ~stop_lat, icon = pega_busstop(1))
  m
}

#' Desenha as trips
#' 
#' A partir de um objeto retornado pela função \code{search_paths}, desenha
#' um mapa com os lugares escolhidos, os raios selecionados, os pontos de 
#' ônibus próximos e os caminhos.
#' 
#' @return Um objeto HTML widget do pacote \code{leaflet}.
#' 
#' @export 
#' @examples 
#' search_path(end1 = 'Avenida 9 de Julho, 2000, São Paulo', 
#'             end2 = 'Av. Pres. Juscelino Kubitschek, 500, São Paulo') %>%
#'  draw_paths()
draw_paths <- function(.data) {
  d <- .data
  
  m <- d %>%
    leaflet::leaflet() %>% 
    leaflet::addTiles() %>% 
    leaflet::addCircles(d$lon1[1], d$lat1[1], d$radius1[1], stroke = FALSE) %>%
    leaflet::addCircles(d$lon2[1], d$lat2[1], d$radius2[1], stroke = FALSE) %>%
    leaflet::addMarkers(d$lon1[1], d$lat1[1]) %>% 
    leaflet::addMarkers(d$lon2[1], d$lat2[1])
  
  sh_id <- unique(d$shape_id)
  if(length(sh_id) > 8) sh_id <- sh_id[1:8]
  co <- substr(rainbow(8, v = .8), 1, 7)[1:length(sh_id)]
  
  for(i in 1:length(sh_id)) {
    d_aux = dplyr::filter(d, shape_id == sh_id[i])
    stops1 <- dplyr::filter(stops, stop_id %in% unique(d_aux$stop_id1))
    stops2 <- dplyr::filter(stops, stop_id %in% unique(d_aux$stop_id2))
    m <- m %>%
      leaflet::addMarkers(~stop_lon, ~stop_lat, 
                          data = stops1, icon = pega_busstop(i)) %>%
      leaflet::addMarkers(~stop_lon, ~stop_lat, 
                          data = stops2, icon = pega_busstop(i))
    
    sh <- dplyr::filter(shapes, shape_id %in% sh_id[i])
    m <- m %>%
      leaflet::addPolylines(lat = ~shape_pt_lat, lng = ~shape_pt_lon,
                            data = sh, smoothFactor = 1.2,
                            opacity = .8, color = co[i],
                            fillColor = NULL, weight = 2)
  }
  m <- m %>%
    leaflet::fitBounds(d$lon1[1], d$lat1[1], d$lon2[1], d$lat2[1])
  m
}

#' Procura pontos de ônibus próximos
#'
#' Calcula distâncias entre um ponto escolhido e os pontos de ônibus, 
#' retornando somente aqueles que estão dentro do raio informado.
#'
#' @param end Endereço para procurar (como se estivesse pesquisando no google maps).
#' @param radius Raio em metros para procura dos pontos mais próximos. Por
#'   padrão vale 300 metros.
#' @param lon Longitude. Informar se o endereço for nulo.
#' @param lat Latitude. Informar se o endereço for nulo.
#' 
#' @return Um data frame contendo um subset de \code{stops} 
#'   (pacote \code{spgtfs}) com os pontos mais próximos, ordenados
#'   por proximidade
#' 
#' @import spgtfs
#' 
#' @export
#' @examples
#' nearby_stops('Avenida Paulista, 1079')
#' nearby_stops('Avenida Paulista, 1079', radius = 200)
#' nearby_stops(lon = -46.6527, lat = -23.5648)
nearby_stops <- function(end = NULL, radius = 300, lon = NULL, lat = NULL) {
  if(is.null(end)) {
    if(is.null(lon) | is.null(lat)) {
      stop('Especifique um endereço ou longitude/latitude.')
    }
    coord <- as.numeric(c(lon, lat))
  } else {
    coord <- as.numeric(ggmap::geocode(end))
  }
  d <- stops
  d$distance <- geodetic_distance_v(coord[1], coord[2], 
                                    stops$stop_lon, stops$stop_lat)
  d <- dplyr::filter(d, distance < radius)
  if(nrow(d) == 0) {
    stop('Nenhum ponto encontrado para o endereço e raio especificados.')
  }
  d <- dplyr::arrange(d, distance)
  d$my_lon <- coord[1]
  d$my_lat <- coord[2]
  d$radius <- radius
  d
}

#' Procura trajetos de ônibus que passam pelos pontos.
#'
#' Obtém os pontos de ônibus mais próximos de cada ponto informado e procura
#' por linhas que passam por esses pontos.
#'
#' @param end1 Endereço de partida.
#' @param end2 Endereço de destino.
#' @param radius1 Raio em metros para procura dos pontos mais próximos do ponto
#'   de partida. Por padrão vale 500 metros.
#' @param radius2 Raio em metros para procura dos pontos mais próximos do ponto
#'   de destino Por padrão vale 500 metros.
#' @param lon1 Longitude de partida. Informar se o endereço for nulo.
#' @param lat1 Latitude de partida. Informar se o endereço for nulo.
#' @param lon2 Longitude de destino. Informar se o endereço for nulo.
#' @param lat2 Latitude de destino. Informar se o endereço for nulo.

#' @return Um data frame contendo um subset de \code{trips} 
#'   (pacote \code{spgtfs}) com as linhas que atendem aos critérios.
#' 
#' @import spgtfs
#' 
#' @export
#' @examples
#' search_path(from = 'Avenida 9 de Julho, 2000', 
#'             to = 'Av. Pres. Juscelino Kubitschek, 500')
search_path <- function(end1 = NULL, end2 = NULL, 
                        radius1 = 300, radius2 = 300,
                        lon1 = NULL, lat1 = NULL,
                        lon2 = NULL, lat2 = NULL) {
  d1 <- nearby_stops(end1, radius1, lon1, lat1)
  d2 <- nearby_stops(end2, radius2, lon2, lat2)

  trips_validas <- stop_times %>% 
    dplyr::distinct(trip_id, stop_id) %>%
    dplyr::left_join(dplyr::bind_rows(d1, d2), 'stop_id') %>%
    dplyr::arrange(distance) %>%
    dplyr::mutate(nc = nchar(trip_id), 
                  tipo_trip = substring(trip_id, nc, nc),
                  tem1 = (stop_id %in% d1$stop_id),
                  tem2 = (stop_id %in% d2$stop_id)) %>%
    dplyr::filter(tem1 | tem2) %>%
    dplyr::group_by(trip_id) %>%
    dplyr::summarise(vale = (n() >= 2),
                     stop_id1 = stop_id[tem1][1],
                     stop_id2 = stop_id[tem2][1],
                     stop_seq1 = stop_sequence[tem1][1],
                     stop_seq2 = stop_sequence[tem2][1]) %>%
    dplyr::filter(vale, !is.na(stop_id1), !is.na(stop_id2))
  
  d <- trips %>% 
    dplyr::inner_join(trips_validas, 'trip_id') %>%
    dplyr::mutate(lon1 = d1$my_lon[1], lat1 = d1$my_lat[1],
                  lon2 = d2$my_lon[1], lat2 = d2$my_lat[1],
                  radius1 = d1$radius[1], radius2 = d2$radius[1])
  d
}

# -----------------------------------------------------------------------------

pega_bus <- function(color) {
  inst <- 'https://raw.githubusercontent.com/jtrecenti/sptrans/master/inst'
  path <- sprintf('%s/icons/%d-bus.png', inst, color)
  js <- invisible(
    V8::JS(sprintf("L.icon({ iconUrl: '%s', iconSize: [32, 37] })", path))
  )
  js
}

pega_busstop <- function(color) {
  inst <- 'https://raw.githubusercontent.com/jtrecenti/sptrans/master/inst'
  path <- sprintf('%s/icons/%d-busstop.png', inst, color)
  js <- invisible(
    V8::JS(sprintf("L.icon({ iconUrl: '%s', iconSize: [32, 37] })", path))
  )
  js
}

