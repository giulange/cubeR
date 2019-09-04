cubeRpath = '/home/zozlak/roboty/BOKU/cube/cubeR'
gridFile = '/home/zozlak/roboty/BOKU/cube/data/shapes/EQUI7_V13_EU_PROJ_TILE_T1.shp'
tmpDir = '/home/zozlak/roboty/BOKU/cube/data/tmp'
rawDir = '/home/zozlak/roboty/BOKU/cube/data/raw'
periodsDir = '/home/zozlak/roboty/BOKU/cube/data/periods'
tilesDir = '/home/zozlak/roboty/BOKU/cube/data/tiles'
overviewsDir = '/home/zozlak/roboty/BOKU/cube/data/overviews'
acubeDir = '/home/zozlak/roboty/BOKU/cube/data/acube'
cacheTmpl = '/home/zozlak/roboty/BOKU/cube/data/cache/{region}_{dateFrom}_{dateTo}_{cloudCovMax}_{bands}'

bands = c('B02', 'B03', 'B04', 'B05', 'B06', 'B07', 'B08', 'B8A', 'B11', 'B12', 'TCI', 'LAI', 'FAPAR', 'FCOVER', 'SCL')
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
  list(bandName = 'CLOUDMASK2', minArea = 0L, bufferSize = 0L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = integer())
)
maskSkipExisting = TRUE

indicatorIndicators = list(
  list(bandName = 'NDVI2',  resolution = 10, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B08', 'B' = 'B04'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)')
)
indicatorSkipExisting = TRUE

whichBands = c('NDVI2')
whichPrefix = 'NMAX'
whichDoyPrefix = 'DOYMAX'
whichBlockSize = 2048
whichSkipExisting = TRUE

compositeBands = list(
  band      = c('B02',       'B03',       'B04',       'B05',       'B06',       'B07',       'B08',       'B8A',       'B11',       'B12',       'TCI',       'LAI',       'FAPAR',     'FCOVER'),
  whichBand = c('NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2'),
  outBand   = c('B02',       'B03',       'B04',       'B05',       'B06',       'B07',       'B08',       'B8A',       'B11',       'B12',       'TCI2',      'LAI2',      'FAPAR2',    'FCOVER2')
)
compositeBlockSize = 2048
compositeSkipExisting = TRUE

tileRawBands = c('B02', 'B03', 'B04', 'B05', 'B06', 'B07', 'B08', 'B8A', 'B11', 'B12', 'TCI', 'LAI', 'FAPAR', 'FCOVER', 'SCL', 'CLOUDMASK2')
tilePeriodBands = list(
  '1 month' = c('B02', 'B03', 'B04', 'B05', 'B06', 'B07', 'B08', 'B8A', 'B11', 'B12', 'NDVI2', 'TCI2', 'LAI2', 'FAPAR2', 'FCOVER2', 'NMAXNDVI2')
)
tileResamplingMethod = 'near'
tileGdalOpts = '-multi -wo NUM_THREADS=2 -wo "COMPRESS=DEFLATE" -wo "TILED=YES" -wo "BLOCKXSIZE=512" -wo "BLOCKYSIZE=512"'
tileSkipExisting = TRUE

renameBands = data.frame(
  band =   c('B02', 'B03', 'B04', 'B05', 'B06', 'B07', 'B08', 'B8A', 'B11', 'B12', 'TCI', 'LAI', 'FAPAR', 'FCOVER', 'SCL', 'CLOUDMASK2', 'B02',  'B03',  'B04',  'B05',  'B06',  'B07',  'B08',  'B8A',  'B11',  'B12',  'TCI2', 'LAI2', 'FAPAR2', 'FCOVER2'),
  name =   c('B02', 'B03', 'B04', 'B05', 'B06', 'B07', 'B08', 'B8A', 'B11', 'B12', 'TCI', 'LAI', 'FAPAR', 'FCOVER', 'SCL', 'CLOUDMASK',  'MB02', 'MB03', 'MB04', 'MB05', 'MB06', 'MB07', 'MB08', 'MB8A', 'MB11', 'MB12', 'MTCI', 'MLAI', 'MFAPAR', 'MFCOVER'),
  type =   c('',    '',    '',    '',    '',    '',    '',    '',    '',    '',    '',    '',    '',      '',       '',    '',           'm',    'm',    'm',    'm',    'm',    'm',    'm',    'm',    'm',    'm',    'm',   'm',    'm',      'm'),
  #                   bands,  TCI,      LAI/etc.,   SCL, CLOUD,         mBands,  mTCI,     mLAI/etc.
  scale =  c(rep(10000, 10),   NA,  rep(1000, 3),    NA,    NA, rep(10000, 10),    NA,  rep(1000, 3)),
  nodata = c(rep(65535, 10),  255, rep(32767, 3),     0,   255, rep(65534, 10),   255, rep(32767, 3)),
  mask =   c( rep(TRUE, 10), TRUE,  rep(TRUE, 3), FALSE, FALSE, rep(FALSE, 10), FALSE, rep(FALSE, 3))
)
