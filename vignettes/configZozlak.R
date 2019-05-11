cubeRpath = '/home/zozlak/roboty/BOKU/cube/cubeR'
gridFile = '/home/zozlak/roboty/BOKU/cube/data/shapes/EQUI7_V13_EU_PROJ_TILE_T1.shp'
tmpDir = '/home/zozlak/roboty/BOKU/cube/data/tmp'
rawDir = '/home/zozlak/roboty/BOKU/cube/data/raw'
tilesDir = '/home/zozlak/roboty/BOKU/cube/data/tiles'

bands = c('B04', 'B08', 'SCL', 'LAI')
nCores = 4
chunksPerCore = 10

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
whichSkipExisting = TRUE

compositeBands = c('NDVI', 'LAI')
compositeBlockSize = 2048
compositeSkipExisting = TRUE

aggregateBands = c('NDVI2')
aggregateBlockSize = 512
aggregateQuantiles = c(0.05, 0.5, 0.95)
aggregateSkipExisting = TRUE

tilesSkipExisting = TRUE
tileResamplingMethod = 'near'
tileGdalOpts = '-multi -wo NUM_THREADS=2'
