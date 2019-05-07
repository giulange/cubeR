args = commandArgs(TRUE)
if (length(args) < 8) {
  stop('This scripts takes parameters: settingsFilePath user pswd regionId dateFrom dateTo period whichBand')
}
names(args) = c('cfgFile', 'user', 'pswd', 'region', 'from', 'to', 'period', 'whichBand')
cat(c('Running composite.R', args, as.character(Sys.time()), '\n'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)
registerDoParallel()

tiles = suppressMessages(
  getImages(args['region'], args['from'], args['to'], rawDir, gridFile, bands, args['user'], args['pswd']) %>%
    imagesToTiles(rawDir, compositeBands) %>%
    mapTilesPeriods(args['period'], args['from']) %>%
    mutate(whichFile = getTilePath(rawDir, .data$tile, .data$period, args['whichBand'])) %>%
    group_by(period, tile, band) %>%
    arrange(period, tile, band, date)
)
if (!all(file.exists(tiles$tileFile)) | !all(file.exists(unique(tiles$whichFile)))) {
  stop('missing tiles')
}

cat(paste('Computing', n_groups(tiles), 'composites', Sys.time(), '\n'))
options(cores = nCores)
composites = foreach(tls = assignToCores(tiles, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  tmp = tls %>% select(period, tile, band) %>% distinct()
  cat(paste(tmp$period, tmp$tile, tmp$band, collapse = ', '), ' (', n_groups(tls), ')\n', sep = '')

  suppressMessages(prepareComposites(tls, rawDir, tmpDir, compositeSkipExisting))
}
cat(paste(nrow(composites), 'composites produced', Sys.time(), '\n'))
