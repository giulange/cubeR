cubeRpath = '/eodc/private/boku/software/cubeR'
gridFile = '/eodc/private/boku/ACube/shapefiles/EQUI7_V13_EU_PROJ_TILE_T1.shp'
tmpDir = '/eodc/private/boku/ACube2/tmp'
rawDir = '/eodc/private/boku/ACube2/raw'
tilesDir = '/eodc/private/boku/ACube2/tiles'
resamplingMethod = 'near'
bands = c('B04', 'B08', 'SCL', 'LAI')
nCores = 8
chunksPerCore = 10

dwnldNCores = 4
dwnldTimeout = 120
dwnldSkipExisting = 'samesize'
dwnldTries = 2

tilesSkipExisting = TRUE
tileGdalOpts = '-multi -wo NUM_THREADS=2'

maskParam = list(
  list(bandName = 'CLOUDMASK1', minArea = 25L, bufferSize = 10L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = c(3L, 8L:10L)),
  list(bandName = 'CLOUDMASK2', minArea = 0L, bufferSize = 0L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = integer())
)
maskSkipExisting = TRUE
maskNCores = 4

ndviCloudmask = 'CLOUDMASK1'
ndviBandName = 'NDVI'
ndviSkipExisting = TRUE

whichBands = 'NDVI'
whichSkipExisting = TRUE
