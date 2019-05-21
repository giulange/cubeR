#' Checks data availbility on the EODC storage
#' @param imageIds vector of image IDs
#' @param conn s2.boku.eodc.eu DBI database connection
#' @param targetDir directory to "download" the data to
#' @param method \code{copy} or \code{symlink}
#' @param basePath base location of the s2.boku.eodc.eu storage
#' @return data frame describing available data
#' @export
#' @import dplyr
downloadEodcPrepare = function(imageIds, conn, targetDir, method, basePath = '/eodc/private/boku/sentinel2/GRANULES') {
  imageIds = unique(imageIds)
  files = list()
  while (length(imageIds) > 0) {
    tmp = imageIds[1:min(1000, length(imageIds))]
    query = sprintf(
      "SELECT granule_id, utm_id, date::date, band_id, filename FROM s2_images JOIN s2_granules USING (granule_id) WHERE image_id IN (%s)",
      paste0('$', seq_along(tmp), collapse = ', ')
    )
    files[[length(files) + 1]] = dplyr::as_tibble(DBI::dbGetQuery(conn, query, tmp))
    imageIds = imageIds[-seq_along(tmp)]
  }
  files = dplyr::bind_rows(files)

  files = files %>%
    dplyr::mutate(
      filename = sprintf(
        '%s/%02d/%02d/%d/%s',
        basePath, floor(.data$granule_id / 100) %% 100, .data$granule_id %% 100, .data$granule_id, .data$filename
      ),
      tileFile = getTilePath(targetDir, .data$utm_id, .data$date, .data$band_id)
    ) %>%
    dplyr::mutate(
      srcExists = file.exists(.data$filename),
      targetExists = file.exists(.data$tileFile)
    ) %>%
    dplyr::mutate(
      symlink = dplyr::if_else(rep(method == 'symlink', dplyr::n()), Sys.readlink(.data$tileFile), NA_character_),
      srcSize = dplyr::if_else(method == 'copy' & .data$srcExists, file.size(.data$filename), NA_real_),
      targetSize = dplyr::if_else(method == 'copy' & .data$targetExists, file.size(.data$tileFile), NA_real_)
    ) %>%
    dplyr::mutate(
      targetExists = .data$targetExists | !is.na(.data$symlink) & .data$symlink != '' # file.exists() reports FALSE on broken symlinks but targetExists should be TRUE for them
    ) %>%
    dplyr::mutate(
      skip = dplyr::coalesce(.data$targetExists & (method == 'symlink' & .data$symlink == .data$filename | method == 'copy' & .data$srcSize == .data$targetSize), FALSE)
    )
  return(files)
}
