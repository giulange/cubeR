# OBLICZANIE STATYSTYK DLA KAFLI W PODZIALE NA LC I KLIMAT
library(dplyr)
dir = '/eodc/private/boku/ACube2/tiles/'
doyBand = '2018y1_DOYMAXNDVI2'
maxBand = 'NDVI2q98'
lcBand = 'LC'
climBand = 'BIOGEO'
outFile = '/eodc/private/boku/ACube2/tiles/doystats.csv'
dirs = list.dirs(dir)
dirs = dirs[nchar(basename(dirs)) == 6]
dirs = dirs[order(dirs)]
dirs = dirs[315:length(dirs)]
for (tile in dirs) {
  cat(tile, '\t', which(tile == dirs), '/', length(dirs), '\n')
  doyFile = list.files(tile, doyBand, full.names = TRUE)
  lcFile = list.files(tile, lcBand, full.names = TRUE)
  climFile = list.files(tile, climBand, full.names = TRUE)
  maxFile = list.files(tile, maxBand, full.names = TRUE)
  if (length(doyFile) != 1 | length(lcFile) != 1 | length(climFile) != 1 | length(maxFile) != 1) {
    cat('\tmissing files doy:', doyFile, 'lc:', lcFile, 'clim:', climFile, 'maxFile:', maxFile, '\n')
    next
  }
  lc = raster::getValues(raster::raster(lcFile))
  ndvi = raster::getValues(raster::raster(maxFile))
  mask = lc >= 200L & lc < 300L & ndvi >= 1000
  mask = mask & !is.na(mask)
  ndvi = ndvi[mask]
  lc = lc[mask]
  if (length(lc) == 0) {
    cat('\tno lc of class 2xx\n')
    next
  }
  doy = raster::getValues(raster::raster(doyFile))[mask]
  clim = dplyr::coalesce(raster::getValues(raster::raster(climFile))[mask], -1L)
  res = dplyr::tibble(lc = lc, clim = clim, ndvi = as.integer(ndvi / 1000), doy = doy)
  res = res %>%
    dplyr::group_by(lc, clim, ndvi, ndvi, doy) %>%
    dplyr::summarize(count = n(), tile = basename(tile)) %>%
    dplyr::select(tile, lc, clim, ndvi, doy, count)
  write.csv(res, outFile, row.names = FALSE, na = '', append = TRUE)

  rm(lc, ndvi, mask, doy, clim, res)
  gc();gc();gc()
}
# for i in `ls -1 /eodc/private/boku/ACube2/tiles/*/*csv`; do tail -n +2 $i >> /eodc/private/boku/ACube2/tiles/doystats.csv; done

#####
# library(dplyr)
# library(ggplot2)
# d = read.csv('~/roboty/BOKU/cube/data/tiles/doystats.csv', header = FALSE) %>% setNames(c('lc', 'clim', 'doy', 'count')) %>% as.tbl()
# dd = d %>%
#   group_by(lc, clim, doy) %>%
#   summarize(count = sum(count)) %>%
#   ungroup() %>%
#   mutate(clim = as.character(clim), lc = as.character(lc))
# dd %>%
#   ggplot(aes(x = doy, group = clim, color = clim)) +
#   geom_density() +
#   facet_wrap(~lc)
