library(shiny)
library(leaflet)

shinyUI(fluidPage(
  includeCSS('www/sty.css'), 
  tags$div(id = 'divL', leafletOutput('map', height = 500))
))
