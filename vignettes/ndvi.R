args = commandArgs(TRUE)
if (length(args) < 6) {
  stop('This scripts takes parameters: settingsFilePath user pswd regionId dateFrom dateTo')
}
names(args) = c('cfgFile', 'user', 'pswd', 'region', 'from', 'to')
cat(c('Running ndvi.R', args, as.character(Sys.time()), '\n'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)
registerDoParallel()

tiles = suppressMessages(
  getImages(args['region'], args['from'], args['to'], rawDir, gridFile, bands, args['user'], args['pswd']) %>%
  imagesToTiles(rawDir, c('B04', 'B08', ndviCloudmasks)) %>%
  group_by(date, tile)
)
if (!all(file.exists(tiles$tileFile))) {
  stop('missing tiles - run tile.R and/or mask.R first')
}

nBands = n_distinct(tiles$band)
cat(paste('Computing', length(ndviBandNames) * nrow(tiles) / nBands, 'NDVI images', Sys.time(), '\n'))
options(cores = nCores)
ndvi = foreach(tls = assignToCores(tiles, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  tmp = tls %>% select(date, tile) %>% distinct()
  cat(paste(tmp$date, tmp$tile, collapse = ', '), ' (', nrow(tls) / nBands, ')\n', sep = '')

  suppressMessages(prepareNdvi(tls, rawDir, tmpDir, ndviCloudmasks, ndviBandNames, skipExisting = ndviSkipExisting))
}
cat(paste(nrow(ndvi), 'NDVI images produced', Sys.time(), '\n'))
