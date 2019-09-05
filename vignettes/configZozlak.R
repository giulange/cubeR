cubeRpath = '/home/zozlak/roboty/BOKU/cube/cubeR'
gridFile = '/home/zozlak/roboty/BOKU/cube/data/shapes/Grid_LAEA5210_100K_polygons.shp'
tmpDir = '/home/zozlak/roboty/BOKU/cube/data/tmp'
rawDir = '/home/zozlak/roboty/BOKU/cube/data/raw'
periodsDir = '/home/zozlak/roboty/BOKU/cube/data/periods'
tilesDir = '/home/zozlak/roboty/BOKU/cube/data/tiles'
overviewsDir = '/home/zozlak/roboty/BOKU/cube/data/overviews'
cacheTmpl = '/home/zozlak/roboty/BOKU/cube/data/cache/{region}_{dateFrom}_{dateTo}_{cloudCovMax}_{bands}'

bands = c('B02', 'B03', 'B04', 'B08', 'B8A', 'B11', 'B12', 'SCL', 'LAI', 'TCI')
cloudCov = 0.4
nCores = 6
chunksPerCore = 10

dwnldMethod = 'copy'
dwnldDbParam = list(host = '127.0.0.1', port = 5433, user = 'zozlak', dbname = 'bokudata')
dwnldMaxRemovals = 2
dwnldNCores = 4
dwnldTimeout = 120
dwnldSkipExisting = 'samesize'
dwnldTries = 2

maskParam = list(
  list(bandName = 'CLOUDMASK1', minArea = 9L, bufferSize = 5L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = c(3L, 8L:10L)),
  list(bandName = 'CLOUDMASK2', minArea = 0L, bufferSize = 0L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = integer())
)
maskSkipExisting = TRUE

indicatorIndicators = list(
  list(bandName = 'NDVI1',  resolution = 10, mask = 'CLOUDMASK1', factor = 10000, bands = c('A' = 'B08', 'B' = 'B04'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)'),
  list(bandName = 'NDVI2',  resolution = 10, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B08', 'B' = 'B04'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)'),
  list(bandName = 'NDTI2',  resolution = 20, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B11', 'B' = 'B12'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)'),
  list(bandName = 'MNDWI2', resolution = 20, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B03', 'B' = 'B11'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)'),
  list(bandName = 'NDBI2',  resolution = 20, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B11', 'B' = 'B8A'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)'),
  list(bandName = 'BSI2',   resolution = 20, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B12', 'B' = 'B04', 'C' = 'B8A', 'D' = 'B02'), equation = '((A.astype(float) + B) - (C + D) ) / (0.0000001 + A + B + C + D)'),
  list(bandName = 'BLFEI2', resolution = 20, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B03', 'B' = 'B04', 'C' = 'B12', 'D' = 'B11'), equation = '((A.astype(float) + B + C) / 3 - D) / (0.0000001 + (A + B + C) / 3 + D)')
)
indicatorSkipExisting = TRUE

whichBands = c('NDVI1', 'NDVI2')
whichPrefix = 'NMAX'
whichDoyPrefix = 'DOYMAX'
whichBlockSize = 2048
whichSkipExisting = TRUE

compositeBands = list(
  band      = c('NDVI1',     'LAI',       'TCI',       'NDVI2',     'LAI',       'TCI'),
  whichBand = c('NMAXNDVI1', 'NMAXNDVI1', 'NMAXNDVI1', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2'),
  outBand   = c('NDVI1',     'LAI1',      'TCI1',      'NDVI2',     'LAI2',      'TCI2')
)
compositeBlockSize = 2048
compositeSkipExisting = TRUE

aggregateBands = c('NDVI2', 'NDTI2', 'MNDWI2', 'NDBI2', 'BSI2', 'BLFEI2')
aggregateBlockSize = 512
aggregateQuantiles = c(0.05, 0.5, 0.95)
aggregateCounts = TRUE
aggregateCountsBand = 'NDVI2'
aggregateCountsOutBand = 'N2'
aggregateSkipExisting = TRUE

tileRawBands = character()
tilePeriodBands = list(
  '1 month' = c('LAI1', 'NDVI1', 'TCI1', 'LAI2', 'NDVI2', 'TCI2'),
  '1 year' = c('NDVI2q05', 'NDVI2q50', 'NDVI2q95')
)
tileResamplingMethod = 'near'
tileGdalOpts = '--config GDAL_CACHEMAX 4096 -multi -wo NUM_THREADS=2 -co "COMPRESS=DEFLATE" -co "TILED=YES" -co "BLOCKXSIZE=512" -co "BLOCKYSIZE=512"'
tileSkipExisting = TRUE

overviewPeriodBands = list(
  '1 month' = c('LAI1',    'LAI2', 'NDVI1', 'NDVI2', 'TCI1', 'TCI2'),
  '1 year'  = c('NDVI2q05', 'NDVI2q50', 'NDVI2q95')
)
overviewNCores = 6
overviewResolution = 100
overviewResamplingMethod = 'bilinear'
overviewGdalOpts = '--config GDAL_CACHEMAX 4096 -multi -wo NUM_THREADS=2 -co "COMPRESS=DEFLATE" -co "TILED=YES" -co "BLOCKXSIZE=512" -co "BLOCKYSIZE=512"'
overviewSkipExisting = TRUE
