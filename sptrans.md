# SPTrans


```r
# Bibliotecas usadas
library(dplyr)
library(ggplot2)
load('shapes.RData')
```


```r
p <- shapes %>%
  ggplot(aes(x=shape_pt_lon, y=shape_pt_lat, colour=shape_id, group=shape_id)) +
  geom_path() +
  geom_point() +
  coord_equal() +
  theme_bw()
print(p)
```

![plot of chunk unnamed-chunk-2](./sptrans_files/figure-html/unnamed-chunk-2.png) 
