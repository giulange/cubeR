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

images = suppressMessages(
  getImages(args['region'], args['from'], args['to'], cloudCov, rawDir, gridFile, bands, args['user'], args['pswd']) %>%
    imagesToTiles(rawDir, tileBands) %>%
    mapRawTiles(gridFile) %>%
    arrange(desc(date), band) %>%
    group_by(date, band)  # `tile` not included to avoid problems when same image is used by two tiles being simultanously processed on other workers
)
if (!all(file.exists(unique(images$file)))) {
  stop('raw file missing - run dwnld.R first')
}

cat(paste('Tiling', n_distinct(images$file), 'images into', n_distinct(images$date, images$band, images$tile), 'tiles', Sys.time(), '\n'))
options(cores = nCores)
tiles = foreach(imgs = assignToCores(images, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  imgs = imgs %>% ungroup()
  tmp = imgs %>% select(date, band) %>% distinct()
  cat(paste(tmp$date, tmp$band, collapse = ', '), ' (', nrow(imgs), 'i, ', n_distinct(imgs$date, imgs$band, imgs$tile), 't)\n', sep = '')

  suppressMessages(prepareTiles(imgs, tilesDir, gridFile, tmpDir, tileResamplingMethod, tilesSkipExisting))
}
cat(paste(nrow(tiles), 'tiles produced', Sys.time(), '\n'))
