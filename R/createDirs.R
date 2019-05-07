#' Creates directories for given paths
#' @param files vector of paths
#' @return vector of created directories
#' @export
createDirs = function(files) {
  dirs = unique(dirname(files))
  dirs = dirs[!dir.exists(dirs)]
  for (i in dirs) {
    dir.create(i, showWarnings = FALSE, recursive = TRUE)
  }
  return(dirs)
}