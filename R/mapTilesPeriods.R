#' Map tiles to time periods
#' @param tiles data.frame of tiles
#' @param period period string matching \code{[number] [unit]} where \code{unit}
#'   is one of day(s), month(s) or year(s)
#' @param startDate beginning of the first period (if NULL, a minimum date among
#'   provided tiles is used)
#' @return tiles data.frame extended with a \code{period} column
#' @export
#' @import dplyr
mapTilesPeriods = function(tiles, period, startDate = NULL) {
  unit = sub('s$', '', sub('^.* ', '', period))
  len = as.integer(sub(' .*$', '', period))

  if (is.null(startDate)) {
    startDate = min(tiles$date)
  }
  startDate = as.Date(startDate)
  if (unit == 'year') {
    startDate = as.integer(substr(startDate, 1, 4))
  }else if (unit == 'month') {
    startDate = as.integer(substr(startDate, 1, 4)) * 12L + as.integer(substr(startDate, 6, 7))
  } else if (unit == 'day') {
    startDate = as.integer(startDate)
  }

  tiles = tiles %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      year = as.integer(substr(.data$date, 1, 4)),
      month = as.integer(substr(.data$date, 1, 4)) * 12L + as.integer(substr(.data$date, 6, 7)),
      day = as.integer(as.Date(.data$date))
    ) %>%
    dplyr::mutate(period = .data[[unit]]) %>%
    dplyr::mutate(
      period = as.integer((.data$period - startDate) / len) * len + startDate
    ) %>%
    select(-.data$year, -.data$month, -.data$day)

  if (unit == 'year') {
    tiles$period = paste0(tiles$period, 'y', len)
  }else if (unit == 'month') {
    tiles$period = sprintf('%d-%02dm%d', as.integer(tiles$period / 12), tiles$period %% 12, len)
  } else if (unit == 'day') {
    tiles$period = as.Date(tiles$period, origin = '1970-01-01')
    tiles$period = sprintf('%sd%d', format(tiles$period, '%Y-%j'), len)
  }

  return(tiles)
}