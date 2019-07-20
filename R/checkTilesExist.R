#' Checks if all tiles exist and reports if not
#' @param d data frame containing the \code{tileFile} column
#' @export
checkTilesExist = function(d) {
  filter = file.exists(d$tileFile)
  if (!all(filter)) {
    d = d[!filter, ]
    save(d, file = 'missing.RData')
    stop('missing tiles ', nrow(d))
  }
}
