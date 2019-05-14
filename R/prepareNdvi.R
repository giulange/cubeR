#' Computes NDVI tiles
#' @details
#' Computation is done using gdal_calc.py.
#' @param input a data frame describing tiles obtained by row-binding data
#'   returned by the \code{\link{prepareTiles}} and \code{\link{prepareMasks}}
#'   functions
#' @param targetDir a directory where tiles should be saved (a separate
#'   subdirectory for each tile will be created)
#' @param tmpDir a directory for temporary files
#' @param cloudmaskBands name of bands to be used as cloudmasks
#' @param bandNames output band names
#' @param skipExisting should already existing tiles be skipped?
#' @return data frame describing generated NDVI tiles
#' @import dplyr
#' @export
prepareNdvi = function(input, targetDir, tmpDir, cloudmaskBands = 'CLOUDMASK', bandNames = 'NDVI', skipExisting = TRUE) {
  stopifnot(
    is.vector(cloudmaskBands), is.vector(bandNames), length(cloudmaskBands) == length(bandNames)
  )

  input = input %>%
    dplyr::ungroup()
  masks = input %>%
    dplyr::filter(.data$band %in% cloudmaskBands) %>%
    dplyr::inner_join(dplyr::tibble(band = cloudmaskBands, outBand = bandNames)) %>%
    dplyr::select(.data$date, .data$tile, .data$tileFile, .data$outBand) %>%
    dplyr::rename(maskFile = .data$tileFile)
  red = input %>%
    dplyr::filter(.data$band == 'B04') %>%
    dplyr::select(.data$date, .data$tile, .data$tileFile) %>%
    dplyr::rename(redFile = .data$tileFile)
  nir = input %>%
    dplyr::filter(.data$band == 'B08') %>%
    dplyr::select(.data$date, .data$tile, .data$tileFile) %>%
    dplyr::rename(nirFile = .data$tileFile)

  processed = red %>%
    dplyr::inner_join(nir) %>%
    dplyr::inner_join(masks) %>%
    dplyr::mutate(
      outFile = getTilePath(targetDir, .data$tile, .data$date, .data$outBand)
    )

  skipped = dplyr::tibble(tileFile = character())
  if (skipExisting) {
    tmp = file.exists(processed$outFile)
    skipped = processed %>%
      dplyr::filter(tmp) %>%
      dplyr::rename(band = .data$outBand, tileFile = .data$outFile) %>%
      dplyr::select(.data$date, .data$tile, .data$band, .data$tileFile)
    processed = processed %>%
      dplyr::filter(!tmp)
  }

  if (nrow(processed) > 0) {
    createDirs(processed$outFile)

    processed = processed %>%
      dplyr::mutate(
        tmpFile = paste0(tmpDir, '/', basename(.data$outFile))
      ) %>%
      dplyr::mutate(
        command = sprintf(
          'gdal_calc.py --quiet -A %s -B %s -C %s --calc "10000 * (A.astype(float) - B) / (0.0000001 + A + B)" --outfile %s --overwrite --type Int16 --NoDataValue -32768 --co "COMPRESS=DEFLATE" --co "TILED=YES" --co "BLOCKXSIZE=512" --co "BLOCKYSIZE=512" && mv %s %s',
          shQuote(.data$nirFile), shQuote(.data$redFile), shQuote(.data$maskFile), shQuote(.data$tmpFile), shQuote(.data$tmpFile), shQuote(.data$outFile)
        )
      )
    tmpFiles = processed$tmpFile
    on.exit({
      unlink(tmpFiles)
    })

    processed = processed %>%
      dplyr::group_by(.data$date, .data$tile, .data$outBand) %>%
      dplyr::do({
        system(.data$command, ignore.stdout = TRUE)
        dplyr::as.tbl(data.frame(band = .data$outBand, tileFile = .data$outFile, stringsAsFactors = FALSE))[file.exists(.data$outFile), ]
      }) %>%
      dplyr::ungroup()
  }

  return(bind_rows(processed, skipped))
}
