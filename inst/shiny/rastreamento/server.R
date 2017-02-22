library(shiny)
library(xtable)
require(ggplot2)
require(scales)
library(magrittr)
library(httr)
library(jsonlite)

bindEvent <- function(eventExpr, callback, env=parent.frame(), quoted=FALSE) {
  eventFunc <- exprToFunction(eventExpr, env, quoted)
  initialized <- FALSE
  invisible(observe({
    eventVal <- eventFunc()
    if (!initialized)
      initialized <<- TRUE
    else
      isolate(callback())
  }))
}

tema <- theme_bw() +
  theme(axis.text.x=element_text(angle=45, hjust=1))


#___________________________________________________________________________________________________
# shinyServer
#___________________________________________________________________________________________________
shinyServer(function(input, output, session) {
  
  #_________________________________________________________________________________________________
  # BD com as posições lat/long da linha selecionada
  posicao <- reactive({
    invalidateLater(3000, session)
    # Pega infos em formato JSON com GET's
    # site de interesse: http://www.sptrans.com.br/desenvolvedores/APIOlhoVivo/Documentacao.aspx?1
    posicao <- GET(paste0(url_sptrans, "Posicao?codigoLinha=", input$linha)) 
    
    if(posicao$status_code == 200) {
      posicao <- posicao %>% 
        as.character %>% 
        fromJSON
      hr <- posicao$hr
      return(posicao$vs %>% as.data.frame %>% mutate(hr = hr))
    } else {
      return(NULL)
    }
  })
  
  linha <- reactive({
    linhas %>% filter(CodigoLinha %in% input$linha)
  })
  
  #_________________________________________________________________________________________________
  # Dados
  output$posicao <- renderTable({
    return(posicao())
  }, options=list(iDisplayLength = 10))
  #_________________________________________________________________________________________________
  
  observe({
    df <- posicao()
    map$clearMarkers()
    map$addMarker(df$py, df$px)
  })
  
  #_________________________________________________________________________________________________
  # GeoVis
  map <- createLeafletMap(session, 'map')
  
  bindEvent(input[['map_marker_click']], function() {
    event <- input[['map_marker_click']]
    map$clearPopups()
    
    pos <- posicao()
    lin <- linha()
    content <- as.character(tagList(
      "Linha: ", lin$CodigoLinha, tags$br(),
      "Próxima parada ID: ", pos$p
    ))
    map$showPopup(event[['lat']], 
                  event[['lng']], 
                  content, 
                  event[['id']])
  })  
  #_________________________________________________________________________________________________
  output$pos <- renderTable({posicao()})
  output$lin <- renderTable({linha()[,c("DenominacaoTPTS", "DenominacaoTSTP", "Circular")]})
  #_________________________________________________________________________________________________
})