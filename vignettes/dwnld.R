args = commandArgs(TRUE)
if (length(args) < 6) {
  stop('This scripts takes parameters: settingsFilePath user pswd regionId dateFrom dateTo')
}
names(args) = c('cfgFile', 'user', 'pswd', 'region', 'from', 'to')
cat(paste0(c('Running dwnld.R', args, as.character(Sys.time()), '\n'), collapse = '\t'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)

registerDoParallel()

S2_initialize_user(args['user'], args['pswd'])

images = suppressMessages(getImages(args['region'], args['from'], args['to'], cloudCov, rawDir, bands)) %>%
  arrange(date, band)
cat('Downloading\n')
if (dwnldMethod %in% c('copy', 'symlink')) {
  dbConn = DBI::dbConnect(RPostgres::Postgres(), host = dwnldDbParam$host, port = dwnldDbParam$port, dbname = dwnldDbParam$dbname, user = dwnldDbParam$user)
  fls = suppressMessages(downloadEodcPrepare(images$imageId, dbConn, rawDir, dwnldMethod))
  cat(sprintf('%d/%d/%d\ttotal/ready/to delete\t%s\n', nrow(fls), sum(fls$skip), sum(fls$targetExists & !fls$skip), Sys.time()))
  fls = suppressMessages(downloadEodcPerform(fls, dwnldMethod, dwnldMaxRemovals))
  cat(sprintf('%d/%d/%d\ttotal/ok/downloaded\t%s\n', nrow(fls), sum(fls$skip | coalesce(fls$success, FALSE)), sum(fls$success, na.rm = TRUE), Sys.time()))
} else {
options(cores = dwnldNCores)
  toGo = images %>%
      arrange(desc(date), utm, band) %>%
      select(url, file)
  while (nrow(toGo) > 0) {
    cat(sprintf('%d/%d\ttotal/ok\t%s\n', nrow(images), nrow(images) - nrow(toGo), as.integer(100 * (nrow(images) - nrow(toGo)) / nrow(images)), Sys.time()))
    results = foreach(tg = assignToCores(toGo, dwnldNCores, chunksPerCore), .combine = c) %dopar% {
      cat(tg$file[1], nrow(tg), '\n')
      try(sentinel2::S2_download(tg$url, tg$file, progressBar = FALSE, skipExisting = dwnldSkipExisting, timeout = dwnldTimeout, tries = dwnldTries, zip = FALSE), silent = TRUE)
    }
    toGo = toGo[!results, ]
  }
  cat(sprintf('%d/%d\ttotal/ok\t%s\n', nrow(images), nrow(images), Sys.time()))
}
