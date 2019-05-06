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

tiles = suppressMessages(getTiles(gridFile, args['region'], args['from'], args['to'], c(ndviCloudmask, 'B04', 'B08'), args['user'], args['pswd'], tilesDir)) %>%
  group_by(date, tile)
if (!all(file.exists(tiles$tileFile))) {
  stop('missing tiles - run tile.R and/or mask.R first')
}

cat(paste('Computing', nrow(tiles) / 3, 'NDVI images', Sys.time(), '\n'))
options(cores = nCores)
ndvi = foreach(tls = assignToCores(tiles, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  tmp = tls %>% select(date, tile) %>% distinct()
  cat(paste(tmp$date, tmp$tile, collapse = ', '), ' (', nrow(tls) / 3, ')\n', sep = '')

  suppressMessages(prepareNdvi(tls, tilesDir, tmpDir, ndviCloudmask, ndviBandName, skipExisting = ndviSkipExisting))
}
cat(paste(nrow(ndvi), 'NDVI images produced', Sys.time(), '\n'))
