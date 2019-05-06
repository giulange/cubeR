args = commandArgs(TRUE)
if (length(args) < 6) {
  stop('This scripts takes parameters: settingsFilePath user pswd regionId dateFrom dateTo')
}
cat(c('Running tile.R', args, as.character(Sys.time()), '\n'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)

registerDoParallel()

S2_initialize_user(args[2], args[3])
projection = sf::st_crs(sf::st_read(gridFile, quiet = TRUE))
images = suppressMessages(getImages(args[4], args[5], args[6], rawDir, projection, bands)) %>%
  mapRawTiles(gridFile) %>%
  arrange(desc(date), band, tile) %>%
  group_by(date, band, tile)  # crucial for assignToCores()
if (!all(file.exists(unique(images$file)))) {
  stop('raw file missing - run dwnld.R first')
}

cat(paste('Tiling', n_distinct(images$file), 'images into', n_groups(images), 'tiles', Sys.time(), '\n'))
options(cores = nCores)
tiles = foreach(imgs = assignToCores(images, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  tmp = imgs %>% select(date, band) %>% distinct()
  cat(paste(tmp$date, tmp$band, collapse = ', '), ' (', nrow(imgs), ', ', n_groups(imgs), ')\n', sep = '')

  suppressMessages(prepareTiles(imgs, tilesDir, gridFile, tmpDir, resamplingMethod, tilesSkipExisting))
}
cat(paste(nrow(tiles), 'tiles produced', Sys.time(), '\n'))
