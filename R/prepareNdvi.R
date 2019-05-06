#' Computes NDVI tiles
#' @details
#' Computation is done using gdal_calc.py.
#' @param tiles a data frame describing tiles obtained by row-binding data
#'   returned by the \code{\link{prepareTiles}} and \code{\link{prepareMasks}}
#'   functions
#' @param targetDir a directory where tiles should be saved (a separate
#'   subdirectory for each tile will be created)
#' @param tmpDir a directory for temporary files
#' @param cloudmaskBand name of the band containing a cloud mask
#' @param bandName output band name
#' @param skipExisting should already existing tiles be skipped?
#' @return data frame describing generated NDVI tiles
#' @import dplyr
#' @export
prepareNdvi = function(tiles, targetDir, tmpDir, cloudmaskBand = 'CLOUDMASK', bandName = 'NDVI', skipExisting = TRUE) {
  ndvi = tiles %>%
    dplyr::select(.data$date, .data$tile, .data$band, .data$tileFile) %>%
    dplyr::group_by(.data$date, .data$tile) %>%
    dplyr::filter(.data$band %in% c(cloudmaskBand, 'B04', 'B08')) %>%
    dplyr::mutate(band = dplyr::if_else(.data$band == cloudmaskBand, 'CLOUDMASK', .data$band)) %>%
    tidyr::spread(.data$band, .data$tileFile) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      tileFile = getTilePath(targetDir, .data$tile, .data$date, bandName)
    ) %>%
    dplyr::mutate(
      tmpFile = paste0(tmpDir, basename(.data$tileFile))
    ) %>%
    dplyr::mutate(
      command = sprintf(
        'gdal_calc.py --quiet -A "%s" -B "%s" -C "%s" --calc "10000 * (A.astype(float) - B) / (0.0000001 + A + B)" --outfile %s --overwrite --type Int16 --NoDataValue -32768 --co "COMPRESS=DEFLATE" && mv %s %s',
        .data$B08, .data$B04, .data$CLOUDMASK, .data$tmpFile, .data$tmpFile, .data$tileFile
      )
    )

  skipped = dplyr::tibble(tileFile = character())
  if (skipExisting) {
    tmp = file.exists(ndvi$tileFile)
    skipped = ndvi %>%
      dplyr::filter(tmp) %>%
      dplyr::mutate(band = bandName) %>%
      dplyr::select(.data$date, .data$tile, .data$band, .data$tileFile)
    ndvi = ndvi %>%
      dplyr::filter(!tmp)
  }

  if (nrow(ndvi) > 0) {
    ndvi = ndvi %>%
      dplyr::group_by(.data$date, .data$tile) %>%
      dplyr::do({
        system(.data$command, ignore.stdout = TRUE)
        data.frame(band = bandName, tileFile = .data$tileFile, stringsAsFactors = FALSE)
      }) %>%
      dplyr::ungroup()
  }

  return(bind_rows(skipped, ndvi))
}
