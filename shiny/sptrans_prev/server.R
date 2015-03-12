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


shinyServer(function(session, input, output) {
  output$tabela <- renderTable({
    invalidateLater(10000, session)
    d <- olhovivo_pega_previsao_linhas_paradas(cods$route_id, cods$stop_id.x)
    d %>%
      arrange(t) %>%
      mutate(nome = ifelse(Sentido == 1, DenominacaoTPTS, DenominacaoTSTP)) %>%
      select(linha, nome, t, a, py, px)
  })
  
})