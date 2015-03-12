context('posicao')

library(leaflet)
library(dplyr)
library(stringr)

# m <- leaflet() %>% 
#   addTiles() %>% 
#   setView(-46.674362, -23.586822, zoom = 15)

x1 <- stops %>%
  filter(str_detect(stop_name, 'Vargas C/B')) %>%
  inner_join(stop_times, 'stop_id') %>%
  select(stop_name, stop_id, trip_id, stop_lon, stop_lat) %>%
  inner_join(trips, 'trip_id')

x2 <- stops %>%
  filter(stop_id %in% c(340015459, 340015468, 340015325)) %>%
  inner_join(stop_times, 'stop_id') %>%
  select(stop_name, stop_id, trip_id) %>%
  inner_join(trips, 'trip_id') %>%
  select(trip_id, stop_name, stop_id)

cods <- inner_join(x1, x2, 'trip_id') %>% 
  select(-service_id, -trip_id) %>%
  head(10)

m <- leaflet_desenha_shapes(shape_ids = cods$shape_id)
m <- leaflet_mapeia_linhas(cods$route_id, sentido = cods$direction_id, m)
m <- addCircles(m, lng = ~ stop_lon, lat = ~ stop_lat, data = distinct(x1, stop_id))
setView(m, -46.654434, -23.555406, 15)

test_that('login', {
  expect_is(olhovivo_login(), 'response')
})

test_that('posicao', {
  expect_is(olhovivo_pega_posicoes(cod_linha), 'data.frame')
  expect_is(leaflet_mapeia_linhas(cod_linhas), c('leaflet', 'htmlwidget'))
  expect_is(leaflet_desenha_shapes(cod_linhas), c('leaflet', 'htmlwidget'))
})
