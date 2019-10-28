#' Maps indicators list to a data frame
#' @param ind list of indicators
#' @return data frame
#' @import dplyr
#' @export
#' @examples
#' indicators = list(
#'   list(
#'     bandName = 'NDVI2',
#'     resolution = 10,
#'     mask = 'CLOUDMASK2',
#'     factor = 10000,
#'     bands = c('A' = 'B04', 'B' = 'B08'),
#'     equation = '(A.astype(float) - B) / (0.0000001 + A + B)'
#'   ),
#'   list(bandName = 'NDTI2',
#'     resolution = 20,
#'     mask = 'CLOUDMASK2',
#'     factor = 10000,
#'     bands = c('A' = 'B11', 'B' = 'B12'),
#'     equation = '(A.astype(float) - B) / (0.0000001 + A + B)'
#'   )
#' )
#' indicatorsToTibble(indicators)
indicatorsToTibble = function(ind) {
  ind = dplyr::tibble(i = ind) %>%
    dplyr::mutate(
      i = purrr::map(.data$i, function(x){
        x$bands = stats::setNames(c(x$bands, x$mask), c(names(x$bands), 'Z'))
        res = as.data.frame(x, stringsAsFactors = FALSE)
        res$name = rownames(res)
        return(res)
      })
    ) %>%
    tidyr::unnest(.data$i) %>%
    dplyr::rename(
      band = .data$bands,
      outBand = .data$bandName
    )
  return(ind)
}
