context('posicao')

library(leaflet)
library(dplyr)
library(stringr)
load('data/routes.rda')

# m <- leaflet() %>% 
#   addTiles() %>% 
#   setView(-46.674362, -23.586822, zoom = 15)

cod_linhas <- routes %>%
  filter(str_detect(route_long_name, 'Olimpia|Itaim Bibi'), 
         str_detect(route_id, '106|6401')) %>%
  with(route_id)

test_that('login', {
  expect_is(olhovivo_login(), 'response')
})

test_that('posicao', {
  expect_is(olhovivo_pega_posicoes(cod_linha), 'data.frame')
  expect_is(leaflet_mapeia_linhas(cod_linhas), c('leaflet', 'htmlwidget'))
})


