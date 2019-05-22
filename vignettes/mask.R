args = commandArgs(TRUE)
if (length(args) < 4) {
  stop('This scripts takes parameters: settingsFilePath regionId dateFrom dateTo')
}
names(args) = c('cfgFile', 'region', 'from', 'to')
t0 = Sys.time()
cat(paste0(c('Running masks.R', args, as.character(Sys.time()), '\n'), collapse = '\t'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)

registerDoParallel()

# get corresponding tiles
tiles = suppressMessages(
  getCache(args['region'], args['from'], args['to'], args['cfgFile']) %>%
    imagesToTiles(rawDir, 'SCL')
)
if (!all(file.exists(tiles$tileFile))) {
  stop('missing tiles')
}

cat(paste('Preparing', nrow(tiles) * length(maskParam), 'masks', Sys.time(), '\n'))
options(cores = nCores)
masks = foreach(tls = assignToCores(tiles, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  masksTmp = list()
  for (i in maskParam) {
    tmp = tls %>% select(date, tile) %>% distinct()
    cat(i$bandName, ' ', paste(tmp$date, tmp$tile, collapse = ', '), ' (', nrow(tls), ')\n', sep = '')

    masksTmp[[length(masksTmp) + 1]] = suppressMessages(prepareMasks(tls, rawDir, tmpDir, i$bandName, i$minArea, i$bufferSize, i$invalidValues, i$bufferedValues, maskSkipExisting))
  }
  bind_rows(masksTmp)
}
logProcessingResults(masks, t0)
