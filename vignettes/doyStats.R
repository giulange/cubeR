# OBLICZANIE STATYSTYK DLA KAFLI W PODZIALE NA LC I KLIMAT
library(dplyr)
dir = '/eodc/private/boku/ACube2/tiles/'
doyBand = '2018y1_DOYMAXNDVI2'
lcBand = 'LC'
climBand = 'BIOGEO'
dirs = list.dirs(dir)
dirs = dirs[nchar(basename(dirs)) == 6]
dirs = dirs[order(dirs)]
dirs = dirs[315:length(dirs)]
for (tile in dirs) {
  outFile = paste0(tile, '/2018y1_DOYMAXNDVI2COUNT_', basename(tile), '.csv')
  if (file.exists(outFile)) {
    next
  }
  cat(tile, '\t', which(tile == dirs), '/', length(dirs), '\n')
  doyFile = list.files(tile, doyBand, full.names = TRUE)
  lcFile = list.files(tile, lcBand, full.names = TRUE)
  climFile = list.files(tile, climBand, full.names = TRUE)
  if (length(doyFile) != 1 | length(lcFile) != 1 | length(climFile) != 1) {
    cat('\tmissing files doy:', doyFile, 'lc:', lcFile, 'clim:', climFile, '\n')
    next
  }
  lc = raster::getValues(raster::raster(lcFile))
  lcMask = lc >= 200L & lc < 300L
  lc = lc[lcMask]
  if (length(lc) == 0) {
    cat('\tno lc of class 2xx\n')
    next
  }
  doy = raster::getValues(raster::raster(doyFile))[lcMask]
  clim = raster::getValues(raster::raster(climFile))[lcMask]
  lcu = unique(lc)
  climu = unique(clim)
  res = dplyr::tibble(lc = rep(lcu, length(climu)), clim = rep(climu, each = length(lcu)), dist = vector('list', length(lcu) * length(climu)))
  for (i in seq_along(res$lc)) {
    res$dist[[i]] = dplyr::tibble(count = tabulate(doy[lc == res$lc[i] & clim == res$clim[i]], 366), doy = 1:366)
  }
  res = res %>%
    tidyr::unnest() %>%
    dplyr::filter(count > 0) %>%
    dplyr::select(.data$lc, .data$clim, .data$doy, .data$count)
  write.csv(res, outFile, row.names = FALSE, na = '')
  
  rm(lc, lcMask, doy, clim, res)
}
# for i in `ls -1 /eodc/private/boku/ACube2/tiles/*/*csv`; do tail -n +2 $i >> /eodc/private/boku/ACube2/tiles/doystats.csv; done
