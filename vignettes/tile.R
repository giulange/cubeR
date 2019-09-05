args = commandArgs(TRUE)
if (length(args) < 4) {
  stop('This scripts takes parameters: settingsFilePath regionId dateFrom dateTo')
}
names(args) = c('cfgFile', 'region', 'from', 'to')
t0 = Sys.time()
cat(paste0(c('Running tile.R', args, as.character(Sys.time()), '\n'), collapse = '\t'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)

registerDoParallel()
options(cores = nCores)

tilesRaw = getCache(args['region'], args['from'], args['to'], args['cfgFile']) %>%
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
checkTilesExist(images)

regionFile = getCachePath(cacheTmpl, args['region'], args['from'], args['to'], cloudCov, bands, 'geojson')
images = foreach(tls = assignToCores(images, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  suppressMessages(mapTilesGrid(tls, gridFile, regionFile))
}
images = images %>%
  tidyr::nest(tileFile, .key = tileFiles) %>%
  ungroup()

cat(paste('Creating', nrow(images), 'tiles', Sys.time(), '\n'))
tiles = foreach(tls = assignToCores(images, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  tmp = tls %>% select(period, tile, band) %>% distinct()
  cat(paste(tmp$period, tmp$tile, tmp$band, collapse = ', '), ' (', nrow(tls), ')\n', sep = '')

  suppressMessages(prepareTiles(tls, tilesDir, gridFile, tmpDir, tileResamplingMethod, tileSkipExisting, gdalOpts = tileGdalOpts))
}
logProcessingResults(tiles, t0)
