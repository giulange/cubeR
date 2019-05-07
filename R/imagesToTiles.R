#' Converts an images data frame into a tiles data frame
#' @details Conversion means simply keeping only required columns and renaming
#' few of them (utm becomes tile, file becomes tileFile)
#' @param images data frame with images list obtained form
#'   \code{\link{getImages}}
#' @return converted data frame
#' @export
#' @import dplyr
imagesToTiles = function(images) {
  result = images %>%
    dplyr::select(.data$date, .data$utm, .data$band, .data$file) %>%
    dplyr::rename(tile = .data$utm, tileFile = .data$file)
  return(result)
}