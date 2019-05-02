args = commandArgs(TRUE)
if (length(args) < 6) {
  stop('This scripts takes parameters: settingsFilePath user pswd regionId dateFrom dateTo')
}
cat(c('Running ndvi.R', args, as.character(Sys.time()), '\n'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)
registerDoParallel()

tiles = suppressMessages(getTiles(gridFile, args[4], args[5], args[6], c(ndviCloudmask, 'B04', 'B08'), args[2], args[3], tilesDir))
if (!all(file.exists(tiles$tileFile))) {
  stop('missing tiles - run tile.R and/or mask.R first')
}

cat(paste('Computing', nrow(tiles) / 3, ' NDVI images', Sys.time(), '\n'))
options(cores = nCores)
ndvi = foreach(tls = tiles %>% group_by(date, tile) %>% group_split(), .combine = bind_rows) %dopar% {
  cat(tls$date[1], tls$tile[1], '\n')
  ndviTmp = suppressMessages(prepareNdvi(tls, tilesDir, ndviCloudmask, ndviBandName, skipExisting = ndviSkipExisting))
  ndviTmp
}
cat(paste(nrow(ndvi), 'NDVI images produced', Sys.time(), '\n'))
