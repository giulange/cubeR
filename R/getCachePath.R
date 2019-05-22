#' Returns a path to the raw images cache file
#' @param template path template may contain placeholders \code{\{region\},
#'   \{dateFrom\}, \{dateTo\}, \{cloudCovMax\}, \{bands\}} which are substituted
#'   with corresponding parameter values.
#' @param region region placeholder value
#' @param dateFrom dateFrom placeholder value
#' @param dateTo dateTo placeholder value
#' @param cloudCovMax cloudCovMax placeholder value
#' @param bands bands placeholder value being a vector of band names (serialized
#'   to a string using \code{_} as a separator)
#' @param ext cache file extension
#' @return path to the cache file
#' @export
getCachePath = function(template, region, dateFrom, dateTo, cloudCovMax, bands, ext = 'csv') {
  template = gsub('\\{region\\}', region, template)
  template = gsub('\\{dateFrom\\}', dateFrom, template)
  template = gsub('\\{dateTo\\}', dateTo, template)
  template = gsub('\\{cloudCovMax\\}', cloudCovMax, template)
  template = gsub('\\{bands\\}', paste0(bands, collapse = '_'), template)
  return(paste0(template, '.', ext))
}
