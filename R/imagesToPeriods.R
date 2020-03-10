#' Generates a list of file paths on the periods-level from the raw-level files
#' list.
#' @param images data frame with images list obtained form
#'   \code{\link{getImages}}
#' @param period period string matching \code{[number] [unit]} where \code{unit}
#'   is one of day(s), month(s) or year(s)
#' @param targetDir a directory storing periods-level rasters
#' @param bands a vector of periods-level bands
#' @param startDate beginning of the first period (if NULL, a minimum date among
#'   provided tiles is used) - see \code{\link{mapTilesPeriods}}
#' @return converted data frame
#' @export
#' @import dplyr
imagesToPeriods = function(images, period, targetDir, bands, startDate = NULL) {
  bands = dplyr::tibble(band = bands, x = 1L)
  tiles = images %>%
    dplyr::filter(band == dplyr::first(.data$band)) %>%
    mapTilesPeriods(period, startDate) %>%
    dplyr::select(.data$utm, .data$period) %>%
    dplyr::distinct() %>%
    dplyr::rename(tile = .data$utm) %>%
    dplyr::mutate(x = 1L) %>%
    dplyr::inner_join(bands) %>%
    dplyr::select(-.data$x) %>%
    dplyr::mutate(tileFile = getTilePath(targetDir, .data$tile, .data$period, .data$band))
  return(tiles)
}