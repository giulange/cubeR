args = commandArgs(TRUE)
if (length(args) < 6) {
  stop('This scripts takes parameters: settingsFilePath user pswd regionId dateFrom dateTo')
}
cat(c('Running dwnld.R', args, as.character(Sys.time()), '\n'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)

registerDoParallel()

S2_initialize_user(args[2], args[3])
projection = sf::st_crs(sf::st_read(gridFile, quiet = TRUE))

images = suppressMessages(getImages(args[4], args[5], args[6], rawDir, projection, bands)) %>%
  arrange(date, band)
cat('Downloading\n')
options(cores = dwnldNCores)
toGo = images %>%
    arrange(desc(date), utm, band) %>%
    select(url, file)
while (nrow(toGo) > 0) {
  cat(sprintf('%d/%d (%d%%) %s\n', nrow(images) - nrow(toGo), nrow(images), as.integer(100 * (nrow(images) - nrow(toGo)) / nrow(images)), Sys.time()))
  toGo = toGo %>%
    mutate(core = rep_len(1:(dwnldNCores * 10), nrow(.))) %>%
    group_by(core)
  results = foreach(tg = toGo %>% group_split(), .combine = c) %dopar% {
    cat(tg$file[1], '\n')
    try(sentinel2::S2_download(tg$url, tg$file, progressBar = FALSE, skipExisting = dwnldSkipExisting, timeout = dwnldTimeout, tries = dwnldTries, zip = FALSE), silent = TRUE)
  }
  toGo = toGo[!results, ]
}
cat(sprintf('%d/%d (100%%) %s\n', nrow(images), nrow(images), Sys.time()))
