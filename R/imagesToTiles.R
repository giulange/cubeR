#' Converts an images data frame into a tiles data frame
#' @details Conversion means simply keeping only required columns and renaming
#' few of them (utm becomes tile, file becomes tileFile)
#' @param images data frame with images list obtained form
#'   \code{\link{getImages}}
#' @param targetDir a directory where tiles should be saved (a separate
#'   subdirectory for each tile will be created)
#' @param bandsLocal vector of local band names to be included
#' @return converted data frame
#' @export
#' @import dplyr
imagesToTiles = function(images, targetDir, bandsLocal = character()) {
  bands = dplyr::tibble(x = 1L, band = bandsLocal)
  result = images %>%
    dplyr::select(.data$date, .data$utm) %>%
    dplyr::distinct() %>%
    dplyr::rename(tile = .data$utm) %>%
    dplyr::mutate(x = 1L) %>%
    dplyr::inner_join(bands) %>%
    dplyr::select(-.data$x) %>%
    dplyr::mutate(tileFile = getTilePath(targetDir, .data$tile, .data$date, .data$band))
  createDirs(result$tileFile)
  return(result)
}