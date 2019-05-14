cubeRpath = '/home/zozlak/roboty/BOKU/cube/cubeR'
gridFile = '/home/zozlak/roboty/BOKU/cube/data/shapes/Grid_LAEA5210_100K_polygons.shp'
tmpDir = '/home/zozlak/roboty/BOKU/cube/data/tmp'
rawDir = '/home/zozlak/roboty/BOKU/cube/data/raw'
tilesDir = '/home/zozlak/roboty/BOKU/cube/data/tiles'

bands = c('B04', 'B08', 'SCL', 'LAI', 'TCI')
cloudCov = 0.4
nCores = 4
chunksPerCore = 10

dwnldMethod = 'copy'
dwnldDbParam = list(host = '127.0.0.1', port = 5433, user = 'zozlak', dbname = 'bokudata')
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
ndviBandNames = c('NDVI', 'NDVI2')
ndviSkipExisting = TRUE

whichBands = c('NDVI', 'NDVI2')
whichPrefix = 'NMAX'
whichBlockSize = 2048
whichSkipExisting = FALSE

compositeBands = c('NDVI', 'LAI')
compositeBlockSize = 2048
compositeSkipExisting = FALSE

aggregateBands = c('NDVI2')
aggregateBlockSize = 512
aggregateQuantiles = c(0.05, 0.5, 0.95)
aggregateSkipExisting = FALSE

tileBands = c('LAI', 'NDVI')
tileSkipExisting = TRUE
tileResamplingMethod = 'near'
tileGdalOpts = '-multi -wo NUM_THREADS=2'
