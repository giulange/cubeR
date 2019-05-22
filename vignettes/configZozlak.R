cubeRpath = '/home/zozlak/roboty/BOKU/cube/cubeR'
gridFile = '/home/zozlak/roboty/BOKU/cube/data/shapes/Grid_LAEA5210_100K_polygons.shp'
tmpDir = '/home/zozlak/roboty/BOKU/cube/data/tmp'
rawDir = '/home/zozlak/roboty/BOKU/cube/data/raw'
periodsDir = '/home/zozlak/roboty/BOKU/cube/data/periods'
tilesDir = '/home/zozlak/roboty/BOKU/cube/data/tiles'
overviewsDir = '/home/zozlak/roboty/BOKU/cube/data/overviews'
cacheTmpl = '/home/zozlak/roboty/BOKU/cube/data/cache/{region}_{dateFrom}_{dateTo}_{cloudCovMax}_{bands}'

bands = c('B04', 'B08', 'SCL', 'LAI', 'TCI')
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

ndviCloudmasks = c('CLOUDMASK1', 'CLOUDMASK2')
ndviBandNames = c('NDVI1', 'NDVI2')
ndviSkipExisting = TRUE

whichBands = c('NDVI1', 'NDVI2')
whichPrefix = 'NMAX'
whichBlockSize = 2048
whichSkipExisting = TRUE

compositeBands = list(
  band      = c('NDVI1',     'LAI',       'TCI',       'NDVI2',     'LAI',       'TCI'),
  whichBand = c('NMAXNDVI1', 'NMAXNDVI1', 'NMAXNDVI1', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2'),
  outBand   = c('NDVI1',     'LAI1',      'TCI1',      'NDVI2',     'LAI2',      'TCI2')
)
compositeBlockSize = 2048
compositeSkipExisting = TRUE

aggregateBands = c('NDVI2')
aggregateBlockSize = 512
aggregateQuantiles = c(0.05, 0.5, 0.95)
aggregateSkipExisting = TRUE

tileRawBands = character()
tilePeriodBands = list(
  '1 month' = c('LAI1', 'NDVI1', 'TCI1', 'LAI2', 'NDVI2', 'TCI2'),
  '1 year' = c('NDVI2q05', 'NDVI2q50', 'NDVI2q95')
)
tileResamplingMethod = 'near'
tileGdalOpts = '-multi -wo NUM_THREADS=2 -wo "COMPRESS=DEFLATE" -wo "TILED=YES" -wo "BLOCKXSIZE=512" -wo "BLOCKYSIZE=512"'
tileSkipExisting = TRUE

overviewBands = c('LAI1', 'LAI2')
overviewResolution = 100
overviewResamplingMethod = 'bilinear'
overviewGdalOpts = '-multi -wo NUM_THREADS=2 -wo "COMPRESS=DEFLATE" -wo "TILED=YES" -wo "BLOCKXSIZE=512" -wo "BLOCKYSIZE=512"'
overviewSkipExisting = TRUE
