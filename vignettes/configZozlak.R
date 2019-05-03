cubeRpath = '/home/zozlak/roboty/BOKU/cube/cubeR'
gridFile = '/home/zozlak/roboty/BOKU/cube/data/shapes/EQUI7_V13_EU_PROJ_TILE_T1.shp'
tmpDir = '/home/zozlak/roboty/BOKU/cube/data/tmp'
rawDir = '/home/zozlak/roboty/BOKU/cube/data/raw'
tilesDir = '/home/zozlak/roboty/BOKU/cube/data/tiles'
resamplingMethod = 'near'
bands = c('B04', 'B08', 'SCL', 'LAI')
nCores = 2
chunksPerCore = 3

dwnldNCores = 2
dwnldTimeout = 120
dwnldSkipExisting = 'samesize'
dwnldTries = 2

tilesSkipExisting = TRUE

maskParam = list(
  list(bandName = 'CLOUDMASK1', minArea = 25L, bufferSize = 10L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = c(3L, 8L:10L)),
  list(bandName = 'CLOUDMASK2', minArea = 0L, bufferSize = 0L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = integer())
)
maskSkipExisting = TRUE
maskNCores = 4

ndviCloudmask = 'CLOUDMASK1'
ndviBandName = 'NDVI'
ndviSkipExisting = TRUE
