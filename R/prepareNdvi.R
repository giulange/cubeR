#' Computes NDVI tiles
#' @param tiles a data frame describing tiles obtained by row-binding data
#'   returned by the \code{\link{prepareTiles}} and \code{\link{prepareMasks}}
#'   functions
#' @param targetDir a directory where tiles should be saved (a separate
#'   subdirectory for each tile will be created)
#' @param cloudmaskBand name of the band containing a cloud mask
#' @param bandName output band name
#' @param skipExisting should already existing tiles be skipped?
#' @return data frame describing generated NDVI tiles
#' @import dplyr
#' @export
prepareNdvi = function(tiles, targetDir, cloudmaskBand = 'CLOUDMASK', bandName = 'NDVI', skipExisting = TRUE) {
  ndvi = tiles %>%
    dplyr::select(date, tile, band, tileFile) %>%
    dplyr::group_by(date, tile) %>%
    dplyr::filter(band %in% c(cloudmaskBand, 'B04', 'B08')) %>%
    dplyr::mutate(band = dplyr::if_else(band == cloudmaskBand, 'CLOUDMASK', band)) %>%
    tidyr::spread('band', 'tileFile') %>%
    dplyr::mutate(
      tileFile = getTilePath(targetDir, tile, date, bandName)
    ) %>%
    dplyr::mutate(
      command = sprintf(
        'gdal_calc.py -A "%s" -B "%s" -C "%s" --calc "10000 * (A.astype(float) - B) / (0.0000001 + A + B)" --outfile %s --overwrite --type Int16 --NoDataValue -32768 --co "COMPRESS=DEFLATE"',
        B08, B04, CLOUDMASK, tileFile
      )
    )

  skipped = dplyr::tibble(tileFile = character())
  if (skipExisting) {
    tmp = file.exists(ndvi$tileFile)
    skipped = ndvi %>%
      dplyr::filter(tmp) %>%
      dplyr::mutate(band = ndviBandName) %>%
      dplyr::select(date, tile, band, tileFile)
    ndvi = ndvi %>%
      dplyr::filter(!tmp)
  }

  ndvi = ndvi %>%
    dplyr::group_by(date, tile) %>%
    dplyr::do({
      system(.$command, ignore.stdout = TRUE)
      dplyr::tibble(band = bandName, tileFile = .$tileFile)
    })

  return(bind_rows(skipped, ndvi))
}
