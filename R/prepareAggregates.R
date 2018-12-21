#' Aggregates data into months
#' @details
#' The aggregation is performed by taking value for a given pixel corresponding
#' to a date when this pixel had highest NDVI value. To do so an additional band
#' called \code{WHICH} is computed storing the corresponding date index for
#' every pixel.
#' @param tiles a data frame describing tiles obtained by row-binding data
#'   returned by the \code{\link{prepareTiles}}, \code{\link{prepareMasks}} and
#'   \code{\link{prepareNdvi}} functions
#' @param targetDir a directory where computed aggregates should be stored
#' @param tmpDir a directory for temporary files
#' @return data frame describing computed aggregated images
#' @import dplyr
#' @export
prepareAggregates = function(tiles, targetDir, tmpDir) {
  # skip nodata values because gdal_calc makes pixel a nodata one if it's nodata in any of input bands
  # as we are searching for maximum NDVI it will work fine on the gdal_calc step until the nodata value is lower then any valid value
  nodata = tiles %>%
    dplyr::mutate(
      nodataFile = paste0(tmpDir, '/', date, '_', band, '_', tile, '.vrt')
    ) %>%
    dplyr::mutate(
      command = paste0('gdal_translate -a_nodata none "', tileFile, '" "', nodataFile, '"')
    )
  nodata = nodata %>%
    dplyr::group_by(date, band, tile) %>%
    do({
      system(.$command, ignore.stdout = TRUE)
      dplyr::data_frame(tileFile = .$tileFile, nodataFile = .$nodataFile)
    })
  on.exit({
    unlink(nodata$nodataFile)
  })
  print(Sys.time())

  ndviMax = nodata %>%
    dplyr::filter(band == 'NDVI') %>%
    dplyr::mutate(
      month = substr(date, 1, 7)
    ) %>%
    dplyr::group_by(month, tile) %>%
    dplyr::arrange(month, tile) %>%
    dplyr::mutate(
      calc1 = LETTERS[dplyr::row_number()],
      calc2 = paste0(dplyr::row_number(), ' * (', LETTERS[dplyr::row_number()], ' == Z)'),
      arg = paste0('-', LETTERS[dplyr::row_number()], ' "', nodataFile, '"'),
    ) %>%
    dplyr::summarize(
      stage1Command = sprintf(
        'gdal_calc.py %s --calc "%s" --outfile {STAGE1FILE} --overwrite --type Int16 --NoDataValue -32768',
        paste0(arg, collapse = ' '),
        sub('maximum[(]A[)]', 'A', paste0(paste0(rep('maximum(', n()), collapse = ''), paste0(calc1, collapse = '), '), ')'))
      ),
      stage2Command = sprintf(
        'gdal_calc.py -Z {STAGE1FILE} %s --calc "%s" --outfile {STAGE2FILE} --overwrite --type Byte --NoDataValue 0 --co "COMPRESS=DEFLATE"',
        paste0(arg, collapse = ' '),
        sub('maximum[(]1 [*] [(]A == Z[)][)]', 'A == Z', paste0(paste0(rep('maximum(', n()), collapse = ''), paste0(calc2, collapse = '), '), ')'))
      )
    ) %>%
    dplyr::group_by(month, tile) %>%
    dplyr::mutate(
      stage1File = paste0(tmpDir, '/', month, '_', tile, '_which.tif'),
      stage2File = paste0(targetDir, '/', month, '_', tile, '_WHICH.tif')
    ) %>%
    dplyr::mutate(
      stage1Command = sub('[{]STAGE1FILE[}]', stage1File, stage1Command),
      stage2Command = sub('[{]STAGE2FILE[}]', stage2File, sub('[{]STAGE1FILE[}]', stage1File, stage2Command))
    )
  ndviMax = ndviMax %>%
    dplyr::group_by(month, tile) %>%
    do({
      ret = system(.$stage1Command, ignore.stdout = TRUE)
      if (ret != 0) cat(.$stage1Command, '\n')
      ret = system(.$stage2Command, ignore.stdout = TRUE)
      if (ret != 0) cat(.$stage2Command, '\n')
      unlink(.$stage1File)
      dplyr::data_frame(whichFile = .$stage2File)
    })
  print(Sys.time())

  agg = nodata %>%
    dplyr::mutate(
      month = substr(date, 1, 7)
    ) %>%
    dplyr::group_by(month, tile, band) %>%
    dplyr::arrange(month, tile, band) %>%
    dplyr::mutate(
      calc = paste0(LETTERS[dplyr::row_number()], ' * (Z == ', dplyr::row_number(), ')'),
      arg = paste0('-', LETTERS[dplyr::row_number()], ' "', nodataFile, '"')
    ) %>%
    dplyr::summarize(
      command = sprintf(
        'gdal_calc.py -Z {WHICHFILE} %s --calc "%s" --outfile {AGGFILE} --co "COMPRESS=DEFLATE"',
        paste0(arg, collapse = ' '), paste0(calc, collapse = ' + ')
      )
    ) %>%
    dplyr::inner_join(ndviMax) %>%
    dplyr::mutate(
      aggFile = paste0(targetDir, '/', month, '_', tile, '_', band, '.tif'),
    ) %>%
    dplyr::group_by(month, tile, band) %>%
    dplyr::mutate(
      command = sub('[{]WHICHFILE[}]', whichFile, sub('[{]AGGFILE[}]', aggFile, command))
    )
  agg = agg %>%
    dplyr::group_by(month, tile, band) %>%
    dplyr::do({
      system(.$command, ignore.stdout = TRUE)
      dplyr::data_frame(aggFile = .$aggFile)
    })
  return(agg)
}