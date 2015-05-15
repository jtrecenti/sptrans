sptrans
====================

A SPTrans nasceu em 1995 e é hoje responsável por quase todo o sistema de
transporte no município de São Paulo. Como São Paulo é o município mais
populoso do Brasil (e o 
[sétimo do mundo!](http://pt.wikipedia.org/wiki/Lista_das_cidades_mais_populosas_do_mundo))
, o desafio é bem grande.

A SPTrans também mantém uma das API's mais divertidas de São Paulo, o OlhoVivo.
Com essa API é possível extrair informações em tempo real da localização
de todos os ônibus, previsões de chegada, etc. Além disso, ela utiliza os
padrões [GTFS](https://developers.google.com/transit/gtfs/reference?hl=pt-br) 
para organizar informações sobre as linhas ativas, os pontos de ônibus e tudo
mais.

Hoje em dia, temos diversos aplicativos mobile e sites que usam essa API.
Faça uma busca por "sptrans" na Google Play, por exemplo, e verá muitos
apps que ajudam a planejar rotas de ônibus.

E por que não brincar com essas informações no R? Bom, pensando nisso fiz esse
pacote, que ajuda a configurar a API, baixar os dados da SPTrans em tempo real
e criar alguns gráficos básicos usando o pacote 
[`leaflet`](https://rstudio.github.io/leaflet/) do RStudio.

## Instalando o pacote

O pacote ainda não está disponível no CRAN. Para instalar via GitHub, você
precisará instalar o pacote `devtools` e então rodar


```r
devtools::install_github('jtrecenti/spgtfs') # dados GTFS
devtools::install_github('jtrecenti/sptrans') # funcoes e API
```

Carregue o pacote com o comando `library` 


```r
library(spgtfs)
library(sptrans)
```

## Configurando a API OlhoVivo

Para acessar a API OlhoVivo, você precisará primeiro de um _token_ de acesso,
que é uma sequência de letras e números geradas aleatoriamente pela SPTrans,
por exemplo:

```
233f343e2ad2a3bf483eae00c316cfdd516c3xxxd21b6a3e916645877e137b6f
```

Para isso, siga os seguintes passos

1. Acesse a [área de desenvolvedores da SPTrans](http://www.sptrans.com.br/desenvolvedores/Cadastro.aspx) 
e crie uma conta.  
2. Quando conseguir logar, acesse a página "Meus Aplicativos" da API Olho Vivo,
e clique em "Adicionar novo aplicativo".  
3. Preencha o formulário com suas informações. Só é necessário preencher o nome
e a descrição. Você pode escolher o nome que quiser. Se tudo der certo, você 
receberá um token de acesso.  
4. Vá para a pasta "home" de seu usuário (se não souber o que é isso, rode
`normalizePath("~/")` no R.).
5. Crie/edite um arquivo chamado `.Renviron` (isso mesmo, com um ponto na 
frente) e coloque o conteúdo

```
OLHOVIVO_PAT=seu_token_aqui

```
Por exemplo:
```
OLHOVIVO_PAT=233f343e2ad2a3bf483eae00c316cfdd516c3xxxd21b6a3e916645877e137b6f

```
**OBS:** O arquivo `.Renviron` deve ter uma linha vazia no final. Por exemplo,
se seu arquivo contém só o token da API OlhoVivo, seu arquivo deve ter duas
linhas com uma linha vazia.

6. Reinicie sua sessão do R. Um jeito fácil de fazer isso no RStudio é pelo
atalho `Ctrl + Shift + F10`.

**Testando se está OK:** O token é acessado pela função `Sys.getenv()` do R.
Após realizar os passos descritos, experimente rodar 
`Sys.getenv('OLHOVIVO_PAT')`. Eu adicionei uma função no pacote chamada
`check_olhovivo()` que faz exatamente isso. Se tudo estiver certo, a função 
imprimirá o seu token e você poderá partir para o próximo passo!

Se encontrar algum problema, acesse 
[essa página](https://github.com/hadley/httr/blob/master/vignettes/api-packages.Rmd#appendix-api-key-best-practices)
, que foi utilizada como base para criar este pacote.


## Dados do GTFS

Antes de sair baixando informações usando a API OlhoVivo, vamos ver um pouco
mais a fundo o que é essa GTFS, para que serve, e como utilizar esses dados
no nosso pacote. 

A Especificação Geral sobre Feeds de Transporte Público é uma padronização
de arquivos para que qualquer lugar do mundo possa divulgar informações
de transporte público num formato único. Isso possibilita empresas como a
[Google](www.google.com) e o aplicativo [Moovit](http://moovitapp.com/pt-br/)
a juntar as informações de vários lugares sem muito trabalho. O padrão
também ajuda os responsáveis pela obteção dos dados, pois é mais fácil
seguir um guia do que planejar a estrutura de dados do zero.

Os dados e a documentação da GTFS estão no pacote `spgtfs`. Após carregar os
dados, é possível visualizar os bds disponíveis em `data(package = 'spgtfs')`. 
Se quiser, por exemplo, verificar a documentação de `shapes`, rode `?shapes`.
É recomendável que o pacote `dplyr` seja carregado antes de trabalhar com
esses dados, para não correr o risco de imprimir dez mil linhas no console.

Vejamos, por exemplo, as linhas de ônibus contidas em `trips`:


```r
head(trips, 10)
```

```
## Source: local data frame [10 x 6]
## 
##    route_id service_id   trip_id            trip_headsign direction_id
## 1   1015-10        USD 1015-10-0    Terminal Jd. Britania            0
## 2   1016-10        USD 1016-10-0             Center Norte            0
## 3   1016-10        USD 1016-10-1       Cemiterio Do Horto            1
## 4   1017-10        USD 1017-10-0               Vila Iorio            0
## 5   1017-10        USD 1017-10-1                    Perus            1
## 6   1018-10        USD 1018-10-0            Metrô Santana            0
## 7   1018-10        USD 1018-10-1                Vila Rosa            1
## 8   1021-10        US_ 1021-10-0        Terminal Pirituba            0
## 9   1021-10        US_ 1021-10-1        Cohab Brasilândia            1
## 10  1024-10        USD 1024-10-0 Conexão Petrônio Portela            0
## Variables not shown: shape_id (chr)
```

### Brincando com o GTFS

As informações do GTFS, por si só, já são bastante úteis.

- Com `trips`, sabemos todas as linhas de ônibus. 
- Com `stops`, sabemos todas as paradas. 
- Com `stop_times`, conseguimos descobrir quais linhas passam em quais pontos.
- Com `shapes`, sabemos todos os trajetos no mapa.

Com a ajuda do pacote `ggmap`, é possível utilizar a API do google para obter 
coordenadas geográficas a partir de endereços. 

Vamos às funções do pacote!

A função `nearby_stops` procura pontos de ônibus próximos a um endereço 
informado. Os pontos próximos são identificados dentro de um raio que por 
padrão é de 300 metros.

Veja alguns exemplos:

Utilização básica.


```r
nearby_stops('Avenida Paulista, 1079')
```

```
## Information from URL : http://maps.googleapis.com/maps/api/geocode/json?address=Avenida+Paulista,+1079&sensor=false
```

```
## Source: local data frame [5 x 9]
## 
##     stop_id                   stop_name
## 1  70002856 R. S. Carlos Do Pinhal, 638
## 2 440016923           Av. Paulista, 901
## 3    706304           Av. Paulista, 900
## 4  70016916          Av. Paulista, 1374
## 5 440015046             Al. Santos, 815
## Variables not shown: stop_desc (chr), stop_lat (dbl), stop_lon (dbl),
##   distance (dbl), my_lon (dbl), my_lat (dbl), radius (dbl)
```

Neste exemplo, não encontramos nenhum ponto de ônibus.


```r
nearby_stops('Avenida Paulista, 1079', radius = 100)
```

Também é possível informar latitude e longitude.


```r
nearby_stops(lon = -46.6527, lat = -23.5648)
```

```
## Source: local data frame [5 x 9]
## 
##     stop_id                   stop_name
## 1  70002856 R. S. Carlos Do Pinhal, 638
## 2 440016923           Av. Paulista, 901
## 3    706304           Av. Paulista, 900
## 4  70016916          Av. Paulista, 1374
## 5 440015046             Al. Santos, 815
## Variables not shown: stop_desc (chr), stop_lat (dbl), stop_lon (dbl),
##   distance (dbl), my_lon (dbl), my_lat (dbl), radius (dbl)
```

A função `draw_stops` desenha o ponto informado, o raio informado, e os pontos
de ônibus próximos.


```r
nearby_stops('Avenida Paulista, 1079', 200) %>% draw_stops()
```

A função `search_path` procura possíveis caminhos de um ponto até outro ponto,
ou seja, procura linhas de ônibus (trips) que passem próximos a duas 
localizações informadas. Até o momento, ainda não é possível identificar 
caminhos com utilização de duas linhas distintas.

```r
search_path(end1 = 'Avenida 9 de Julho, 2000, São Paulo', 
            end2 = 'Av. Pres. Juscelino Kubitschek, 500, São Paulo')
```

```
## Source: local data frame [2 x 17]
## 
##   route_id service_id   trip_id trip_headsign direction_id shape_id vale
## 1  106A-10        USD 106A-10-0    Itaim Bibi            0    55806 TRUE
## 2  6401-10        U__ 6401-10-1    V. Olimpia            1    56520 TRUE
## Variables not shown: stop_id1 (chr), stop_id2 (chr), stop_seq1 (int),
##   stop_seq2 (int), lon1 (dbl), lat1 (dbl), lon2 (dbl), lat2 (dbl), radius1
##   (dbl), radius2 (dbl)
```

A função `draw_paths` desenha os dois pontos informados, os raios informados,
os pontos de ônibus válidos e os caminhos possíveis (no máximo oito).


```r
search_path(end1 = 'Avenida 9 de Julho, 2000, São Paulo', 
            end2 = 'Av. Pres. Juscelino Kubitschek, 500, São Paulo') %>%
  draw_paths()
```

Outro exemplo, aumentando o raio 2.

```r
search_path(end1 = 'Avenida 9 de Julho, 2000, São Paulo', 
            end2 = 'Av. Pres. Juscelino Kubitschek, 500, São Paulo',
            radius2 = 500) %>%
  dplyr::filter(!stringr::str_detect(trip_headsign, 
                                     'Santana|Luz|Band|Armenia|Pedro Ii')) %>%
  # Obs: tirei manualmente as linhas que vão para o lado oposto ao que eu
  # quero, isto é, que vão da JK até a 9 de Julho.
  # Esse é um problema conhecido do pacote.
  draw_paths()
```

## Obtendo informações online

Na versão atual do pacote, temos a função `colect_bus`, que torna possível 
obter as localizações de ônibus a partir de:

- Um conjunto de linhas. Nesse caso, a função retorna a localização em tempo
real de todos os ônibus nas linhas informadas.


```r
trip_ids <- search_path(end1 = 'Avenida 9 de Julho, 2000, São Paulo', 
                        end2 = 'Av. Pres. Juscelino Kubitschek, 500, São Paulo')

trip_ids %>% collect_bus(trip_id, 'trip')
```

```
## Autenticação realizada com sucesso!
```

```
## Source: local data frame [11 x 14]
## 
##    CodigoLinha     p     a        py        px route_id Circular Letreiro
## 1          516 23027  TRUE -23.58664 -46.67721  106A-10    FALSE     106A
## 2          516 23032  TRUE -23.59033 -46.68845  106A-10    FALSE     106A
## 3          516 11953  TRUE -23.54285 -46.63530  106A-10    FALSE     106A
## 4          516 23026  TRUE -23.58982 -46.68827  106A-10    FALSE     106A
## 5          516 23039  TRUE -23.53641 -46.63410  106A-10    FALSE     106A
## 6          516 23056  TRUE -23.50297 -46.62605  106A-10    FALSE     106A
## 7          516 23082  TRUE -23.58950 -46.68815  106A-10    FALSE     106A
## 8          516 23034  TRUE -23.57679 -46.67111  106A-10    FALSE     106A
## 9        33127 76021  TRUE -23.60245 -46.67604  6401-10    FALSE     6401
## 10       33127 76011  TRUE -23.58191 -46.67060  6401-10    FALSE     6401
## 11       33127 76845 FALSE -23.54244 -46.63642  6401-10    FALSE     6401
## Variables not shown: Sentido (int), Tipo (int), DenominacaoTPTS (chr),
##   DenominacaoTSTP (chr), Informacoes (lgl), trip_id (chr)
```

- Um conjunto de rotas. Nesse caso, a função retorna a localização em tempo
real de todos os ônibus nas rotas informadas (lembrando, uma rota pode 
corresponder a uma ou duas linhas).


```r
trip_ids %>% collect_bus(route_id, 'route')
```

```
## Source: local data frame [24 x 13]
## 
##    CodigoLinha     p     a        py        px route_id Circular Letreiro
## 1          359 76854 FALSE -23.57679 -46.67092  6401-10    FALSE     6401
## 2          359 76901 FALSE -23.54918 -46.63986  6401-10    FALSE     6401
## 3          359 76038  TRUE -23.53626 -46.63690  6401-10    FALSE     6401
## 4          359 76899 FALSE -23.59435 -46.68866  6401-10    FALSE     6401
## 5          516 23027  TRUE -23.59562 -46.68837  106A-10    FALSE     106A
## 6          516 23032  TRUE -23.58950 -46.68815  106A-10    FALSE     106A
## 7          516 11953  TRUE -23.54314 -46.63550  106A-10    FALSE     106A
## 8          516 23026  TRUE -23.58923 -46.68805  106A-10    FALSE     106A
## 9          516 23039  TRUE -23.55542 -46.64947  106A-10    FALSE     106A
## 10         516 23056  TRUE -23.52826 -46.63168  106A-10    FALSE     106A
## ..         ...   ...   ...       ...       ...      ...      ...      ...
## Variables not shown: Sentido (int), Tipo (int), DenominacaoTPTS (chr),
##   DenominacaoTSTP (chr), Informacoes (lgl)
```

Para desenhar os ônibus no mapa, basta chamar a função `draw_bus()`.


```r
trip_ids %>% 
  collect_bus(trip_id, 'trip') %>%
  draw_bus()
```

É possível desenhar tanto os ônibus em tempo real quanto os caminhos da
função `draw_paths`


```r
m <- trip_ids %>% draw_paths()
trip_ids %>%
  collect_bus(trip_id, 'trip') %>%
  draw_bus(m)
```

Observe que os ônibus realmente andam!


```r
Sys.sleep(10)
trip_ids %>% 
  collect_bus(trip_id, 'trip') %>%
  draw_bus(m)
```

## TODO

- Previsão de chegada de ônibus nos pontos.
- Melhorar documentação e dat @export em mais funções.
- Adicionar testes e tratamento de exceções.
- Se tiver alguma sugestão ou uma pull request, adicione um issue na 
[página do github](https://github.com/jtrecenti/sptrans).

## Known Issues

- Não trabalha bem com trips no GTFS. Difícil colocar paths somente de "ida" e
não de "volta".

## Agradecimentos

- A Hadley Wickham, que fez um 
[tutorial muito útil](https://github.com/hadley/httr/blob/master/vignettes/api-packages.Rmd)
para criação pacotes no R baseados em API's, e por contribuir no fantástico
pacote `ggmap`.
