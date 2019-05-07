# directory where the package was cloned
cubeRpath = '/eodc/private/boku/software/cubeR'
# file containing the grid (every feture must provide the TILE property)
gridFile = '/eodc/private/boku/ACube/shapefiles/EQUI7_V13_EU_PROJ_TILE_T1.shp'
# directory for storing temporary files
tmpDir = '/eodc/private/boku/ACube2/tmp'
# directory storing rasters before retiling
rawDir = '/eodc/private/boku/ACube2/raw'
# directory storing rasters after retiling to the target grid (see the gridFile parameter)
tilesDir = '/eodc/private/boku/ACube2/tiles'

# list of bands to be downloaded and tiled
bands = c('B04', 'B08', 'SCL', 'LAI')
# number of workers (cores)
nCores = 12
# each worker (core) is assigned chunksPerCore data chunks (generally you shouldn't need to tune this property)
chunksPerCore = 10

# number of parallel downloads
dwnldNCores = 4
# see `?sentinel2::S2_download`
dwnldTimeout = 120
dwnldSkipExisting = 'samesize'
dwnldTries = 2

# should already existing tiles be skipped (TRUE) or reprocessed anyway (FALSE)
tilesSkipExisting = TRUE
# reprojection resampling algorithm - see `man gdalwap``
tileResamplingMethod = 'near'
# additional gdalwarp parameters used while reprojection & retiling - see `man gdalwap``
tileGdalOpts = '-multi -wo NUM_THREADS=2'

# description of cloud masks - parameters passed to prepareMasks() - see `?prepareMasks` (remember minArea and bufferSize unit is a 20m pixel)
maskParam = list(
  list(bandName = 'CLOUDMASK1', minArea = 9L, bufferSize = 5L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = c(3L, 8L:10L)),
  list(bandName = 'CLOUDMASK2', minArea = 0L, bufferSize = 0L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = integer())
)
# should already existing masks be skipped (TRUE) or reprocessed anyway (FALSE)
maskSkipExisting = TRUE

# name of the cloud mask to be used for the NDVI generation
ndviCloudmask = 'CLOUDMASK1'
# generated NDVI image band name
ndviBandName = 'NDVI'
# should already existing NDVI images be skipped (TRUE) or reprocessed anyway (FALSE)
ndviSkipExisting = TRUE

# band names of bands used to compute within-a-period maxima (can be more than one band)
whichBands = c('NDVI')
# should already existing "which" images be skipped (TRUE) or reprocessed anyway (FALSE)
whichSkipExisting = TRUE

# band names of bands for which composites should be computed
compositeBands = c('NDVI', 'LAI')
# should already existing composite images be skipped (TRUE) or reprocessed anyway (FALSE)
compositeSkipExisting = TRUE
