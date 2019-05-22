args = commandArgs(TRUE)
if (length(args) < 4) {
  stop('This scripts takes parameters: settingsFilePath regionId dateFrom dateTo')
}
names(args) = c('cfgFile', 'region', 'from', 'to')
t0 = Sys.time()
cat(paste0(c('Running ndvi.R', args, as.character(Sys.time()), '\n'), collapse = '\t'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)
registerDoParallel()

tiles = suppressMessages(
  getCache(args['region'], args['from'], args['to'], args['cfgFile']) %>%
  imagesToTiles(rawDir, c('B04', 'B08', ndviCloudmasks)) %>%
  group_by(date, tile)
)
if (!all(file.exists(tiles$tileFile))) {
  stop('missing tiles')
}

nBands = n_distinct(tiles$band)
cat(paste('Computing', length(ndviBandNames) * nrow(tiles) / nBands, 'NDVI images', Sys.time(), '\n'))
options(cores = nCores)
ndvi = foreach(tls = assignToCores(tiles, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  tmp = tls %>% select(date, tile, band) %>% filter(band %in% ndviCloudmasks) %>% distinct()
  cat(paste(tmp$date, tmp$tile, tmp$band, collapse = ', '), ' (', nrow(tmp), ')\n', sep = '')

  suppressMessages(prepareNdvi(tls, rawDir, tmpDir, ndviCloudmasks, ndviBandNames, skipExisting = ndviSkipExisting))
}
logProcessingResults(ndvi, t0)
