# EKSTRAKCJA WARTOŚCI RASTRÓW

#tilesDir = '~/Pulpit/shapes/'
tilesDir = '/eodc/private/boku/ACube2/tiles'
saveDir = '/eodc/private/boku/ACube2/tmp/extracted'
pointsFile = '/home/zozlak/roboty/BOKU/cube/data/shapes/EU_2018_190611_CPRNC_G_3035_LAEAgridID_QB_NDVI_IMP2015_CLC2018_dec.shp'
nCores = 4
chunksPerCore = 10
rasters = tibble(
  band = c('LC', 'RAIN', 'TEMP', rep(c('NDVI2', 'LAI2', 'TCI2', 'B02', 'B03', 'B04', 'B05', 'B06', 'B07', 'B08', 'B8A', 'B11', 'B12', 'FAPAR2', 'FCOVER2'), each = 12)),
  date = c(rep('1900-01-01', 3), rep(c('2018-01m1', '2018-02m1', '2018-03m1', '2018-04m1', '2018-05m1', '2018-06m1', '2018-07m1', '2018-08m1', '2018-09m1', '2018-10m1', '2018-11m1', '2018-12m1'), 15))
) %>%
  mutate(column = paste0(band, '_', date))

#####

library(dplyr)
library(doParallel, quietly = TRUE)
registerDoParallel()
options(cores = nCores)

d = sf::read_sf(pointsFile)
names(d) = tolower(names(d))
names(d)[2] = 'point_id'
dd = d %>%
  dplyr::select(point_id, th_long, th_lat) %>%
  dplyr::mutate(data = wgs2grid(.data$th_long, .data$th_lat)) %>%
  tidyr::unnest(.data$data) %>%
  dplyr::group_by(tile) %>%
  tidyr::nest()
res = foreach(tls = assignToCores(dd, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  tls %>%
    dplyr::group_by(tile) %>%
    dplyr::do({
      extracted = .data
      for (i in seq_along(rasters$band)) {
        tileFile = getTilePath(tilesDir, .data$tile, rasters$date[i], rasters$band[i])
        if (file.exists(tileFile)) {
          extracted[, rasters$column[i]] = extractPixelValues(.data$data[[1]]$px, .data$data[[1]]$py, tileFile)
        } else {
          warning(paste(tileFile, 'does not exist'))
        }
      }
      save(extracted, file = paste0(saveDir, '/', extracted$tile, '.RData'))
      data.frame(x = 1L)
    })
}


