# directory where the package was cloned
cubeRpath = '/eodc/private/boku/software/cubeR'
# file containing the grid (every feture must provide the TILE property)
gridFile = '/eodc/private/boku/ACube/shapefiles/Grid_LAEA5210_100K_polygons.shp'
# directory for storing temporary files
tmpDir = '/eodc/private/boku/ACube2/tmp'
# directory storing rasters before retiling
rawDir = '/eodc/private/boku/ACube2/raw'
# directory storing rasters after retiling to the target grid (see the gridFile parameter)
tilesDir = '/eodc/private/boku/ACube2/tiles'

# list of bands to be downloaded and tiled
bands = c('B04', 'B08', 'SCL', 'LAI', 'TCI')
# maximal accepted granules' cloud coverage
cloudCov = 0.4
# number of workers (cores)
nCores = 32
# each worker (core) is assigned chunksPerCore data chunks (generally you shouldn't need to tune this property)
chunksPerCore = 10

# download method "download", "copy" or "symlink"
# (two latter ones work only on machines with a direct access to the BOKU's EODC storage)
dwnldMethod = 'symlink'
# s2.boku.eodc.eu database connection paramerters required for the "symlink" download method
dwnldDbParam = list(host = '10.250.16.131', port = 5432, user = 'eodc', dbname = 'bokudata')
## parameters required for the "download" download method
# number of parallel downloads
dwnldNCores = 4
# see `?sentinel2::S2_download`
dwnldTimeout = 120
dwnldSkipExisting = 'samesize'
dwnldTries = 2

# description of cloud masks - parameters passed to prepareMasks() - see `?prepareMasks` (remember minArea and bufferSize unit is a 20m pixel)
maskParam = list(
  list(bandName = 'CLOUDMASK1', minArea = 9L, bufferSize = 5L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = c(3L, 8L:10L)),
  list(bandName = 'CLOUDMASK2', minArea = 0L, bufferSize = 0L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = integer())
)
# should already existing masks be skipped (TRUE) or reprocessed anyway (FALSE)
maskSkipExisting = TRUE

# name of the cloud mask to be used for the NDVI generation
ndviCloudmasks = c('CLOUDMASK1', 'CLOUDMASK2')
# generated NDVI image band name
ndviBandNames = c('NDVI', 'NDVI2')
# should already existing NDVI images be skipped (TRUE) or reprocessed anyway (FALSE)
ndviSkipExisting = TRUE

# band names of bands used to compute within-a-period maxima (can be more than one band)
whichBands = c('NDVI', 'NDVI2')
# prefix preppended to the orignal band name to get the target "which band name'
whichPrefix = 'NMAX'
# processing block size (affects memory usage)
whichBlockSize = 2048
# should already existing "which" images be skipped (TRUE) or reprocessed anyway (FALSE)
whichSkipExisting = TRUE

# band names of bands for which composites should be computed
compositeBands = c('NDVI', 'LAI')
# processing block size (affects memory usage)
compositeBlockSize = 2048
# should already existing composite images be skipped (TRUE) or reprocessed anyway (FALSE)
compositeSkipExisting = TRUE

# bands to be aggregated into quantiles
aggregateBands = c('NDVI2')
# processing block size (affects memory usage)
aggregateBlockSize = 512
# quantiles to be computed
aggregateQuantiles = c(0.05, 0.5, 0.95)
# should already computed quantile images be skipped (TRUE) or reprocessed anyway (FALSE)
aggregateSkipExisting = TRUE

# should already existing tiles be skipped (TRUE) or reprocessed anyway (FALSE)
tilesSkipExisting = TRUE
# reprojection resampling algorithm - see `man gdalwap``
tileResamplingMethod = 'near'
# additional gdalwarp parameters used while reprojection & retiling - see `man gdalwap``
tileGdalOpts = '-multi -wo NUM_THREADS=2'
