library(shiny)
library(sptrans)
library(dplyr)
library(stringr)
library(leaflet)

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
  head(10) %>%
  group_by(stop_id.x) %>%
  mutate(label = paste(route_id, collapse = '<br/>')) %>%
  ungroup

m0 <- leaflet_desenha_shapes(shape_ids = cods$shape_id) %>%
  addCircles(lng = ~ stop_lon,
             lat = ~ stop_lat,
             popup = ~ label,
             data = distinct(cods, stop_id.x)) %>%
  setView(-46.65431, -23.55924, 19)

olhovivo_login()

shinyServer(function(session, input, output) {
  
  output$map <- renderLeaflet({
    invalidateLater(10000, session)
    leaflet_mapeia_linhas(cods$route_id, sentido = cods$direction_id, m0) %>%
      setView(-46.65431, -23.55924, 18)
  })
  
})