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
tiles = suppressMessages(getTiles(gridFile, args[4], args[5], args[6], 'SCL', args[2], args[3], tilesDir))
if (!all(file.exists(tiles$tileFile))) {
  stop('missing tiles - run tile.R first')
}

cat(paste('Preparing', nrow(tiles) * length(maskParam), 'masks', Sys.time(), '\n'))
options(cores = maskNCores)
masks = foreach(tls = assignToCores(tiles, maskNCores, chunksPerCore), .combine = bind_rows) %dopar% {
  masksTmp = list()
  for (i in maskParam) {
    tmp = tls %>% select(date, tile) %>% distinct()
    cat(i$bandName, ' ', paste(tmp$date, tmp$tile, collapse = ', '), ' (', nrow(tls), ')\n', sep = '')

    masksTmp[[length(masksTmp) + 1]] = suppressMessages(prepareMasks(tls, tilesDir, tmpDir, i$bandName, i$minArea, i$bufferSize, i$invalidValues, i$bufferedValues, maskSkipExisting))
  }
  bind_rows(masksTmp)
}
cat(paste(nrow(masks), 'masks produced', Sys.time(), '\n'))
