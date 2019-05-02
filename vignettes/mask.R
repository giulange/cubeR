args = commandArgs(TRUE)
if (length(args) < 6) {
  stop('This scripts takes parameters: settingsFilePath user pswd regionId dateFrom dateTo')
}
cat(c('Running masks.R', args, as.character(Sys.time()), '\n'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)

registerDoParallel()

# get corresponding tiles
S2_initialize_user(args[2], args[3])
projection = sf::st_crs(sf::st_read(gridFile, quiet = TRUE))
tiles = suppressMessages(getImages(args[4], args[5], args[6], rawDir, projection, 'SCL')) %>%
  mapRawTiles(gridFile) %>%
  select(date, band, tile) %>%
  distinct() %>%
  mutate(tileFile = getTilePath(tilesDir, tile, date, band)) %>%
  arrange(date, band, tile)

if (!all(file.exists(tiles$tileFile))) {
  stop('missing tiles - run tile.R first')
}

cat(paste('Preparing', nrow(tiles) * length(masksParam), 'masks', Sys.time(), '\n'))
options(cores = nCores)
masks = foreach(tls = tiles %>% group_by(tileFile) %>% group_split(), .combine = bind_rows) %dopar% {
  masksTmp = list()
  for (i in masksParam) {
    cat(tls$date, tls$tile, i$bandName, '\n')
    masksTmp[[length(masksTmp) + 1]] = suppressMessages(prepareMasks(tls, tilesDir, tmpDir, i$bandName, i$minArea, i$bufferSize, i$invalidValues, i$bufferedValues, masksSkipExisting))
  }
  bind_rows(masksTmp)
}
cat(paste(nrow(masks), 'masks produced', Sys.time(), '\n'))
