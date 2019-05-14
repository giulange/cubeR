args = commandArgs(TRUE)
if (length(args) < 6) {
  stop('This scripts takes parameters: settingsFilePath user pswd regionId dateFrom dateTo')
}
names(args) = c('cfgFile', 'user', 'pswd', 'region', 'from', 'to')
cat(c('Running tile.R', args, as.character(Sys.time()), '\n'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)

registerDoParallel()

tilesRaw = suppressMessages(getImages(args['region'], args['from'], args['to'], cloudCov, rawDir, bands, args['user'], args['pswd'])) %>%
  select(date, utm) %>%
  distinct()
imagesRaw = suppressMessages(
  tilesRaw %>%
    imagesToTiles(rawDir, tileRawBands)
)
imagesPeriods = list()
for (i in seq_along(tilePeriodBands)) {
  imagesPeriods[[i]] = suppressMessages(
    tilesRaw %>%
      mapTilesPeriods(names(tilePeriodBands)[i], args['from']) %>%
      select(period, utm) %>%
      distinct() %>%
      rename(date = period) %>%
      imagesToTiles(periodsDir, tilePeriodBands[[i]])
  )
}
images = imagesRaw %>%
  bind_rows(bind_rows(imagesPeriods)) %>%
  rename(period = date)
if (!all(file.exists(images$tileFile))) {
  stop('missing tiles')
}
images = suppressMessages(
  images %>%
    mapTilesGrid(gridFile) %>%
    tidyr::nest(tileFile, .key = tileFiles) %>%
    ungroup()
)

cat(paste('Creating', nrow(images), 'tiles', Sys.time(), '\n'))
options(cores = nCores)
tiles = foreach(tls = assignToCores(images, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  tmp = tls %>% select(period, tile, band) %>% distinct()
  cat(paste(tmp$period, tmp$tile, tmp$band, collapse = ', '), ' (', nrow(tls), ')\n', sep = '')

  suppressMessages(prepareTiles(tls, tilesDir, gridFile, tmpDir, tileResamplingMethod, tileSkipExisting))
}
logProcessingResults(tiles)
