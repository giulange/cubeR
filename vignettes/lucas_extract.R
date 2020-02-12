# EKSTRAKCJA WARTOŚCI RASTRÓW
library(dplyr)
library(doParallel, quietly = TRUE)
devtools::load_all('../')

#tilesDir = '~/Pulpit/shapes/'
tilesDir = '/eodc/private/boku/ACube2/tiles'
saveDir = '/eodc/private/boku/ACube2/tmp/extracted'
pointsFile = '/eodc/private/boku/ACube2/auxiliary/LUCAS2018 - field_survey/EU_2018_190611.csv'
urbanPointsFile = '/eodc/private/boku/ACube2/auxiliary/LUCAS2018 - field_survey/urban_points_sample.shp'
nCores = 32
chunksPerCore = 10

auxBands = c('LC', 'RAIN', 'TEMP')
auxDates = rep('1900-01-01', 3)
yearlyBands = c('DOYMAXNDVI2', 'N2', 'NDVI2q05', 'NDVI2q50', 'NDVI2q98', 'NDTI2q05', 'NDTI2q50', 'NDTI2q98', 'MNDWI2q05', 'MNDWI2q50', 'MNDWI2q98', 'NDBI2q05', 'NDBI2q50', 'NDBI2q98', 'BSI2q05', 'BSI2q50', 'BSI2q98', 'BLFEI2q05', 'BLFEI2q50', 'BLFEI2q98', 'WS')
yearlyDates = rep('2018y1', 21)
monthlyBands = c('NDVI2', 'LAI2', 'TCI2', 'B02', 'B03', 'B04', 'B05', 'B06', 'B07', 'B08', 'B8A', 'B11', 'B12', 'FAPAR2', 'FCOVER2')
monthlyDates = c('2018-01m1', '2018-02m1', '2018-03m1', '2018-04m1', '2018-05m1', '2018-06m1', '2018-07m1', '2018-08m1', '2018-09m1', '2018-10m1', '2018-11m1', '2018-12m1')
rasters = tibble(
  band = c(auxBands, yearlyBands, rep(monthlyBands, 12)),
  date = c(auxDates, yearlyDates, rep(monthlyDates, each = length(monthlyBands)))
) %>%
  mutate(column = paste0(band, '_', date))

#####

registerDoParallel()
options(cores = nCores)

d = readr::read_csv(pointsFile, guess_max = 300000)
d = bind_rows(d, sf::read_sf(urbanPointsFile) %>% mutate(POINT_ID = -row_number(), class = paste0('U', class)) %>% rename(LC1 = class))
names(d) = tolower(names(d))
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
      print(.data)
      extracted = .data$data[[1]]
      for (i in seq_along(rasters$band)) {
        tileFile = getTilePath(tilesDir, .data$tile, rasters$date[i], rasters$band[i])
        if (file.exists(tileFile)) {
          extracted[, rasters$column[i]] = extractPixelValues(extracted$px, extracted$py, tileFile)
        } else {
          warning(paste(tileFile, 'does not exist'))
        }
      }
      save(extracted, file = paste0(saveDir, '/', .data$tile, '.RData'))
      data.frame(x = 1L)
    })
}
warnings()

