# EKSTRAKCJA WARTOŚCI RASTRÓW

tilesDir = '~/Pulpit/shapes/'
rasters = tibble(
  band = c('LC', 'NDVI2q98'),
  date = c('2018-01-01', '2018y1')
)
d = readr::read_csv('~/Pulpit/shapes/AT-2018-20190611.csv', guess_max = 10000)
names(d) = tolower(names(d))
dd = d %>%
  dplyr::select(point_id, th_long, th_lat) %>%
  dplyr::mutate(data = wgs2grid(.data$th_long, .data$th_lat)) %>%
  tidyr::unnest(.data$data) %>%
  dplyr::group_by(tile) %>%
  tidyr::nest()
for (i in seq_along(rasters$band)) {
  dd = dd %>%
    dplyr::mutate(
      tileFile = getTilePath(tilesDir, .data$tile, rasters$date[i], rasters$band[i])
    ) %>%
    dplyr::mutate(!! rasters$band[i] := purrr::map2(.data$data, .data$tileFile, function(d, f){extractPixelValues(d$px, d$py, f)})) %>%
    dplyr::select(-.data$tileFile)
}
dd = dd %>%
  tidyr::unnest()
