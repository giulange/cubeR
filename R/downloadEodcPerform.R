#' Performs a "direct download" from the EODC storage
#' @param files data frame describing files to be downloaded obtained from
#'   \code{\link{downloadEodcPrepare}} (must contain columns \code{filename,
#'   tileFile, skip, srcExists, targetExists})
#' @param method \code{copy} or \code{symlink}
#' @param maxRemovals maximum number of existing local files to be removed (e.g.
#'   because their size differ from remote ones or they point to a different
#'   location) - eceeding this limit halts the execution
#' @return data frame describing downloaded files
#' @export
#' @import dplyr
downloadEodcPerform = function(files, method, maxRemovals = 2) {
  toRemove = files$targetExists & !files$skip
  stopifnot(sum(toRemove) <= maxRemovals)
  unlink(files$tileFile[toRemove])

  createDirs(files$tileFile)
  processed = files %>%
    dplyr::filter(.data$srcExists & !.data$skip) %>%
    dplyr::mutate(success = FALSE)
  if (nrow(processed) > 0) {
    if (method == 'copy') {
      processed = processed %>%
        dplyr::mutate(
          success = purrr::map2_lgl(.data$filename, .data$tileFile, function(x, y){file.copy(x, y, overwrite = TRUE)})
        )
    } else {
      processed = processed %>%
        dplyr::mutate(
          success = file.symlink(.data$filename, .data$tileFile)
        )
    }
  }

  files = files %>%
    dplyr::left_join(processed)
  return(files)
}
