library(shiny)

#___________________________________________________________________________________________________
# ShinyUI
#___________________________________________________________________________________________________
shinyUI(navbarPage(title='Shiny - SPTrans', collapsable=TRUE, inverse=TRUE, id='tabset',
  header=list(tags$head(tags$link(rel='stylesheet', type='text/css', href='styles.css'))),
  
  tabPanel('Aplicação',
           fluidRow(
             column(12,
                    tags$div(class="outer",
                             leafletMap(outputId="map",
                                        width='100%',
                                        height='100%',
                                        initialTileLayerAttribution='Maps by <a href="http://www.mapbox.com/">Mapbox</a>',
                                        options = list(center = c(-22.46558, -48.7706), zoom = 6)
                             )
                    )
             )
           ),
           absolutePanel(top=51, right='auto', left=250+80, bottom='auto', width="350px", draggable=TRUE, class = "modal controls",
                         h3('Linha'),
                         selectizeInput("linha",
                                        "Número da linha de ônibus",
                                        choices = linhas$CodigoLinha,
                                        selected = "1177"),
                         tableOutput("lin"),
                         h4('Posição dos veículos'),
                         tableOutput("pos")
           ),
           absolutePanel(top='auto', right='auto', left=250+80, bottom=50, width="350px", draggable=TRUE, class = "modal controls",
                         h3("Sobre o app"),
                         "Baseado nos apps ",
                         tags$a(href = "https://github.com/jcheng5/leaflet-shiny/",
                                "Leaflet-Shiny"),
                         "(Joe Cheng) e ",
                         tags$a(href = "https://github.com/abjur/vistemplate",
                                "vistemplate"),
                         "(Julio Trecenti/ABJ).",
                         tags$br(),
                         "Dados fornecidos pela",tags$a(href = "http://www.sptrans.com.br/desenvolvedores/", "SPTrans"),".",
                         tags$br(),
                         "O app simplesmente mostra a posição (atualizada a cada 3 segundos) dos ônibus de uma linha escolhida. Tem o intuito de incentivar ideias de uso do API disponibilizado pela SPTrans."
           )
           
  ),
  tabPanel('Dados', 
           fluidRow(
             column(6, 
                    tableOutput("posicao")
             )
           )
  )
))