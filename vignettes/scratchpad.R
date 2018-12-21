devtools::load_all()
library(sentinel2)
library(dplyr)

setwd('/home/zozlak/roboty/BOKU/cube/cubeR/')
S2_initialize_user('zozlak', '***')
gridFile = '../data/shapes/EQUI7_V13_EU_PROJ_TILE_T1.shp'
projection = sf::st_crs(sf::st_read(gridFile))
tmpDir = '../data/tmp'

images = getImages('AU_cube', '2017-06-01', '2017-06-30', '../data/raw/', projection)
save(images, file = 'vignettes/images.RData')
load('vignettes/images.RData')
sentinel2::S2_download(images$url, images$file) # 975 obrazów od 13:37 do 15:20, łącznie 61 GB

system.time({
  tiles = images %>%
  group_by(date, band) %>%
  do({
    tilesTmp = prepareTiles(., '../data/tiles/', gridFile, tmpDir, 'near')
    tilesTmp %>%
      select(-date, -band)
  })
  save(tiles, file = 'vignettes/tiles.RData')
})
load('vignettes/tiles.RData')

system.time({
  masks = prepareMasks(tiles, tmpDir)
  save(masks, file = 'vignettes/masks.RData')
})
load('vignettes/masks.RData')

system.time({
  ndvi = prepareNdvi(bind_rows(tiles, masks))
  save(ndvi, file = 'vignettes/ndvi.RData')
})
load('vignettes/ndvi.RData')

system.time({
  all = bind_rows(tiles, ndvi, masks)
  agg = prepareAggregates(all, '../data/agg', tmpDir)
  save(agg, file = 'vignettes/agg.RData')
})
load('vignettes/agg.RData')
