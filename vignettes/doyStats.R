# OBLICZANIE STATYSTYK DLA KAFLI W PODZIALE NA LC I KLIMAT
library(dplyr)
dir = '/eodc/private/boku/ACube2/tiles/'
doyBand = '2018y1_DOYMAXNDVI2'
maxBand = 'NDVI2q98'
lcBand = 'LC'
climBand = 'BIOGEO'
dirs = list.dirs(dir, recursive = FALSE)
dirs = dirs[nchar(basename(dirs)) == 6]
dirs = dirs[order(dirs)]
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
  outFile = paste0('/eodc/private/boku/ACube2/tiles/doystats_', basename(tile), '.csv')
  write.csv(res, outFile, row.names = FALSE, na = '')

  rm(lc, ndvi, mask, doy, clim, res)
  gc();gc();gc()
}
# for i in `ls -1 /eodc/private/boku/ACube2/tiles/*/*csv`; do tail -n +2 $i >> /eodc/private/boku/ACube2/tiles/doystats.csv; done

# OBLICZANIE WINTER/SUMMER

dir = '/eodc/private/boku/ACube2/tiles/'
tmpDir = '/eodc/private/boku/ACube2/tmp/'
vrtFile = '/eodc/private/boku/ACube2/tiles/2018y1_WINTERSUMMER.vrt'
xyzDir = '/eodc/private/boku/ACube2/xyz/wintersummer'
doyBand = '2018y1_DOYMAXNDVI2'
lcBand = 'LC'
climBand = 'BIOGEO'
maxBand = 'NDVI2q98'
ndviMin = 3
outBand = '2018y1_WINTERSUMMER'
climates = tibble(
  value = 0:12,
  label =     c('NA', 'Alpine', 'Anatolian', 'Arctic', 'Black sea', 'Continental', 'Macaronesia', 'Mediterranean', 'Pannonian', 'Steppic', 'Atlantic', 'Boreal', 'external'),
  threshold1 = c(160,      170,         150,        1,         150,           160,           999,             150,         150,       150,        100,      170,        999),
  threshold2 = c(999,      225,         999,      999,         999,           999,           999,             999,         999,       200,        999,      220,        999)
)
gdalOpts = '--co="COMPRESS=DEFLATE" --co="TILED=YES" --co="BLOCKXSIZE=512" --co="BLOCKYSIZE=512"'

dirs = list.dirs(dir, recursive = FALSE)
dirs = dirs[nchar(basename(dirs)) == 6]
dirs = dirs[order(dirs)]
th1 = paste0('(C == ', climates$value, ') * ', climates$threshold1, collapse = ' + ')
th2 = paste0('(C == ', climates$value, ') * ', climates$threshold2, collapse = ' + ')
outFiles = character(length(dirs))
for (i in seq_along(dirs)) {
  tile = dirs[i]
  try({
    outFile = paste0(tile, '/', outBand, '_', basename(tile), '.tif')
    tmpFile = paste0(tmpDir, '/', basename(outFile))
    cat(outFile, '\t', which(tile == dirs), '/', length(dirs), '\n')
    doyFile = list.files(tile, doyBand, full.names = TRUE)
    lcFile = list.files(tile, lcBand, full.names = TRUE)
    climFile = list.files(tile, climBand, full.names = TRUE)
    maxFile = list.files(tile, maxBand, full.names = TRUE)
    if (length(doyFile) != 1 | length(lcFile) != 1 | length(climFile) != 1 | length(maxFile) != 1) {
      cat('\tmissing files doy:', doyFile, 'lc:', lcFile, 'clim:', climFile, 'maxFile:', maxFile, '\n')
      next
    }
    command = sprintf(
      'GDAL_CACHEMAX=1024 gdal_calc.py -C %s -D %s -L %s -N %s --calc "(L == 211) * (N >= %d) * (1 + (D > (%s)) + (D > (%s)))" --outfile=%s --NoDataValue=0 --type=Byte --overwrite --quiet %s && mv %s %s',
      shQuote(climFile), shQuote(doyFile), shQuote(lcFile), shQuote(maxFile), ndviMin, th1, th2, shQuote(tmpFile), gdalOpts, shQuote(tmpFile), shQuote(outFile)
    )
    system(command)
    outFiles[i] = outFile
  })
}
writeLines(outFiles, paste0(vrtFile, '.in'))
command = paste0('gdalbuildvrt -input_file_list ', shQuote(paste0(vrtFile, '.in')), ' ', shQuote(vrtFile))
system(command)
unlink(paste0(vrtFile, '.in'))
# --maxZoom 10 --minZoom 0 --verbose
command = sprintf('python python/xyz.py --algorithm near %s %s', vrtFile, xyzDir)
system(command)

#####
library(dplyr)
library(ggplot2)
clim = tibble(clim = c(-1, 1:12), clim2 = c('NA', 'alpine', 'anatolian', 'arctic', 'blackSea', 'continental', 'macaronesian', 'mediterranean', 'pannonian', 'steppic', 'atlantic', 'boreal', 'external'))
lc = tibble(lc = c(211:213, 221:223, 231, 241:244), lc2 = c('arable', 'permanent irr', 'rice', 'vineyard', 'orchard', 'olive', 'pastures', 'permanent', 'complex1', 'complex2', 'agro-forest'))
d = readr::read_csv('~/roboty/BOKU/cube/data/tiles/doystats.csv') %>%
  left_join(clim) %>%
  left_join(lc) %>%
  select(-clim, -lc) %>%
  rename(clim = clim2, lc = lc2)
dd = d %>%
  group_by(lc, clim, doy, ndvi) %>%
  summarize(count = sum(count)) %>%
  ungroup()
# single variable distributions
ndvicount = d %>%
  group_by(ndvi) %>%
  summarize(count = sum(count)) %>%
  ungroup() %>%
  mutate(relcount = round(100 * count / sum(count), 2)) %>%
  arrange(desc(count))
ndvicount
lccount = d %>%
  group_by(lc) %>%
  summarize(count = sum(count)) %>%
  ungroup() %>%
  mutate(relcount = round(100 * count / sum(count), 2)) %>%
  arrange(desc(count))
lccount
climcount = d %>%
  group_by(clim) %>%
  summarize(count = sum(count)) %>%
  ungroup() %>%
  mutate(relcount = round(100 * count / sum(count), 2)) %>%
  arrange(desc(count))
climcount
# most common lc & clim combinations
d %>%
  group_by(lc, clim) %>%
  summarize(count = sum(count)) %>%
  ungroup() %>%
  mutate(relcount = round(100 * count / sum(count), 2)) %>%
  arrange(desc(count)) %>%
  mutate(cumrelcount = cumsum(relcount)) %>%
  filter(cumrelcount < 90)
# graphs
dd %>%
  group_by(lc, clim) %>%
  summarize(count = sum(count)) %>%
  ggplot(aes(x = clim, y = lc, size = count, color = count)) +
  geom_point() +
  scale_size_continuous(limits = c(10^6, 5*10^9), range = c(1, 10)) +
  scale_color_continuous(trans = 'log', limits = c(10^6, 5*10^9))
dd %>%
  semi_join(lccount %>% filter(relcount > 1) %>% select(-count)) %>%
  semi_join(climcount %>% filter(relcount > 1) %>% select(-count)) %>%
  filter(ndvi >= 5 & doy >= 80 & doy <= 320) %>%
  mutate(doy = doy - doy %% 10L) %>%
  group_by(lc, clim, doy) %>%
  summarize(count = sum(count)) %>%
  group_by(lc, clim) %>%
  mutate(relcount = count / sum(count)) %>%
  ggplot(aes(x = doy, y = relcount, group = lc, color = lc)) +
  geom_line() +
  facet_wrap(~clim, scales = 'free_y')
dd %>%
  filter(ndvi >= 5 & doy >= 80 & doy <= 320 & lc == 'arable') %>%
  mutate(doy = doy - doy %% 10L) %>%
  group_by(lc, clim, doy) %>%
  summarize(count = sum(count)) %>%
  group_by(lc, clim) %>%
  mutate(relcount = count / sum(count)) %>%
  ggplot(aes(x = doy, y = relcount, group = lc, color = lc)) +
  geom_line() +
  facet_wrap(~clim, scales = 'free_y')
d %>%
  filter(ndvi >= 5 & doy >= 80 & doy <= 320 & lc == 'arable' & clim == 'continental') %>%
  mutate(x = as.integer(substr(tile, 2, 3)), y = as.integer(substr(tile, 5, 6))) %>%
  mutate(doy = doy - doy %% 10L, x = x - x %% 5L, y = y - y %% 5L) %>%
  group_by(lc, clim, x, y, doy) %>%
  summarize(count = sum(count)) %>%
  group_by(lc, clim, x, y) %>%
  mutate(relcount = count / sum(count)) %>%
  ggplot(aes(x = doy, y = relcount, group = lc, color = lc)) +
  geom_line() +
  facet_grid(y ~ x, scales = 'free_y')
