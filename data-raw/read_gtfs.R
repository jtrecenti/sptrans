# setwd() to gtfs folder downloaded from http://www.sptrans.com.br/desenvolvedores/
library(readr)

frequencies <- read.delim('frequencies.txt', sep = ',', quote = "\"", stringsAsFactors = FALSE)
routes <-      read.delim('routes.txt', sep = ',', quote = "\"", stringsAsFactors = FALSE)
shapes <-      read.delim('shapes.txt', sep = ',', quote = "\"", stringsAsFactors = FALSE)
stops <-       read.delim('stops.txt', sep = ',', quote = "\"", stringsAsFactors = FALSE)
stop_times <-  read.delim('stop_times.txt', sep = ',', quote = "\"", stringsAsFactors = FALSE)
trips <-       read.delim('trips.txt', sep = ',', quote = "\"", stringsAsFactors = FALSE)

save(frequencies, file = 'data/frequencies.rda', compress = TRUE)
save(routes, file = 'data/routes.rda', compress = TRUE)
save(shapes, file = 'data/shapes.rda', compress = TRUE)
save(stops, file = 'data/stops.rda', compress = TRUE)
save(stop_times, file = 'data/stop_times.rda', compress = TRUE)
save(trips, file = 'data/trips.rda', compress = TRUE)