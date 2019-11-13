args = commandArgs(TRUE)
if (length(args) < 4) {
  stop('This scripts takes parameters: settingsFilePath regionId dateFrom dateTo')
}
names(args) = c('cfgFile', 'region', 'from', 'to')
t0 = Sys.time()
cat(paste0(c('Running renameACube.R', args, as.character(Sys.time()), '\n'), collapse = '\t'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)

registerDoParallel()
options(cores = nCores)

# 1. PREPARE RASTERS LIST AND COLLECT METADATA
tilesRaw = getCache(args['region'], args['from'], args['to'], args['cfgFile']) %>%
  mutate(ab = substr(product, 1, 3)) %>%
  select(date, utm, granuleId, ab) %>%
  distinct()
monthEnds = c('01' = 31, '02' = 28, '03' = 31, '04' = 30, '05' = 31, '06' = 30, '07' = 31, '08' = 31, '09' = 30, '10' = 31, '11' = 30, '12' = 31)
tilesPeriods = tilesRaw %>%
  mapTilesPeriods('1 month', args['from']) %>%
  group_by(utm, period) %>%
  summarize(
    granule = list(granuleId),
    dateMin = min(date),
    dateMax = max(date),
    periodMin = paste0(substr(first(period), 1, 7), '-01'),
    periodMax = paste0(substr(first(period), 1, 7), '-', monthEnds[substr(first(period), 6, 7)])
  ) %>%
  ungroup()
tiles = tilesRaw %>%
  mutate(
    granule = purrr::map(granuleId, function(x){x}),
    period = date,
    dateMin = date,
    dateMax = date,
    periodMin = date,
    periodMax = date
  ) %>%
  select(-date) %>%
  bind_rows(tilesPeriods) %>%
  mutate(type = if_else(period == dateMax, '', 'm')) %>%
  inner_join(renameBands)

tileShapes = tiles %>%
  filter(period != dateMax) %>%
  group_by(utm) %>%
  filter(band == first(band)) %>%
  filter(row_number() == 1) %>%
  mutate(
    tileFile = getTilePath(periodsDir, utm, period, band)
  ) %>%
  select(utm, tileFile)
regionFile = getCachePath(cacheTmpl, args['region'], args['from'], args['to'], cloudCov, bands, 'geojson')
tileShapes = suppressMessages(mapTilesGrid(tileShapes, gridFile, regionFile)) %>%
  select(-tileFile, -bbox)
tiles = tiles %>%
  inner_join(tileShapes) %>%
  group_by(tile, type, band, name, period, periodMin, periodMax, scale, nodata, mask) %>%
  summarize(
    ab = coalesce(if_else(n_distinct(ab) > 1L, 'S2-', first(ab)), 'S2-'),
    level = if_else(first(periodMin) == first(periodMax), 'L2A', 'L3A'),
    dateMin = min(dateMin),
    dateMax = max(dateMax),
    granule = paste0(unique(unlist(granule)), collapse = ',')
  ) %>%
  ungroup() %>%
  mutate(
    tileFile = getTilePath(tilesDir, tile, period, band)
  )
checkTilesExist(tiles)

# 2. Compute cloud cover and valid pixel count
cloudCover = tiles %>%
  filter(band == 'SCL' & type == '') %>%
  group_by(tile, period)
cloudCover = foreach(tls = assignToCores(cloudCover, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  cat(paste(tls$period, tls$tile, collapse = ', '), ' (', nrow(tls), ')\n', sep = '')
  tls %>%
    do({
      r = raster::raster(.data$tileFile)
      t = tabulate(raster::getValues(r), 11L)
      tibble(type = '', cloudCover = sum(t[c(3, 8:10)]) / nrow(r) / ncol(r), valid = sum(t) / nrow(r) / ncol(r))
    })
}
validCount = tiles %>%
  filter(band == 'TCI2' & type == 'm') %>%
  group_by(tile, period)
validCount = foreach(tls = assignToCores(validCount, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  cat(paste(tls$period, tls$tile, collapse = ', '), ' (', nrow(tls), ')\n', sep = '')
  tls %>%
    do({
      r = raster::raster(sub('TCI2', 'NMAXNDVI2', .data$tileFile))
      t = tabulate(1L + as.integer(is.na(raster::getValues(r))))
      tibble(type = 'm', valid = t[1] / sum(t))
    })
}
tiles = tiles %>%
  left_join(bind_rows(cloudCover, validCount)) %>%
  ungroup()

# 3. Set metadata
fixedMeta = '-mo "creator=BOKU" -mo "distanceuom=M" -mo "distancevalue=10" -mo "grid=EQUI7" -mo "log_file=" -mo "processing_software=R,gdal" -mo "processing_software_version=0"'
tmp = foreach(tls = assignToCores(tiles, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  cat('chunk\n')
  tls %>%
    mutate(
      command = sprintf('gdal_edit.py %s -mo "sat_product_id=S2-%s" -mo "equi7_tile=EU010M_%sT1" -mo "parent_data_tile=%s" -mo "scale_factor=%s" -mo "processing_date=%s" -mo "query_begin=%s" -mo "query_end=%s" -mo "time_begin=%s" -mo "time_end=%s" -mo "variable_name=%s" -mo "data_coverage=%f" -mo "cloud_coverage=%f" %s', fixedMeta, level, tile, granule, scale, Sys.time(), gsub('-', '', periodMin), gsub('-', '', periodMax), gsub('-', '', dateMin), gsub('-', '', dateMax), name, valid, coalesce(cloudCover, 0), shQuote(tileFile))
    ) %>%
    group_by(row_number()) %>%
    do({
      system(.data$command)
      data.frame()
    })
}

# 4. Rename

tiles = tiles %>%
  mutate(
    targetFile = sprintf('%s/%s/%s_SEN2COR_%s_%s------_%s_%s_EU010M_%sT1.tif', acubeDir, name, gsub(' ', '-', sprintf('%-10s', name)), ab, level, gsub('-', '', periodMin), gsub('-', '', periodMax), tile)
  )
tmp = createDirs(tiles$targetFile)
tmp = file.rename(tiles$tileFile, tiles$targetFile)
