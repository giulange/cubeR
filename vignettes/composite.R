args = commandArgs(TRUE)
if (length(args) < 7) {
  stop('This scripts takes parameters: settingsFilePath user pswd regionId dateFrom dateTo period')
}
names(args) = c('cfgFile', 'user', 'pswd', 'region', 'from', 'to', 'period')
cat(paste0(c('Running composite.R', args, as.character(Sys.time()), '\n'), collapse = '\t'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)
registerDoParallel()

compositeBands = tibble(band = compositeBands) %>%
  mutate(whichBand = names(compositeBands)) %>%
  tidyr::unnest()
tiles = suppressMessages(
  getImages(args['region'], args['from'], args['to'], cloudCov, rawDir, bands, args['user'], args['pswd']) %>%
    imagesToTiles(rawDir, unique(compositeBands$band)) %>%
    mapTilesPeriods(args['period'], args['from']) %>%
    left_join(compositeBands) %>%
    mutate(whichFile = getTilePath(periodsDir, .data$tile, .data$period, whichBand)) %>%
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

  suppressMessages(prepareComposites(tls, periodsDir, tmpDir, paste0(cubeRpath, '/python'), compositeSkipExisting, compositeBlockSize))
}
logProcessingResults(composites)
