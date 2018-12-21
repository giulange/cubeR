#' Computes NDVI tiles
#' @param tiles a data frame describing tiles obtained by row-binding data
#'   returned by the \code{\link{prepareTiles}} and \code{\link{prepareMasks}}
#'   functions
#' @return data frame describing generated NDVI tiles
#' @import dplyr
#' @export
prepareNdvi = function(tiles) {
  ndvi = tiles %>%
    dplyr::group_by(date, tile) %>%
    dplyr::filter(band %in% c('CLOUDMASK', 'B04', 'B08')) %>%
    tidyr::spread('band', 'tileFile') %>%
    dplyr::mutate(
      tileFile = sub('_CLOUDMASK_', '_NDVI_', CLOUDMASK)
    ) %>%
    dplyr::mutate(
      command = sprintf(
        'gdal_calc.py -A "%s" -B "%s" -C "%s" --calc "10000 * (A.astype(float) - B) / (0.0000001 + A + B)" --outfile %s --overwrite --type Int16 --NoDataValue -32768 --co "COMPRESS=DEFLATE"',
        B08, B04, CLOUDMASK, tileFile
      )
    )
  ndvi = ndvi %>%
    dplyr::group_by(date, tile) %>%
    dplyr::do({
      system(.$command, ignore.stdout = TRUE)
      dplyr::data_frame(band = 'NDVI', tileFile = .$tileFile)
    })
  return(ndvi)
}
