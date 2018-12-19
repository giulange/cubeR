#' Prepares valid pixel masks
#' @description
#' Creates a binary valid pixels mask frpm an S2's SCL image.
#'
#' It is a two-steps procedure. In the first step groups of
#' \code{bufferedValues} pixels are buffered with a radius of a
#' \code{bufferSize}. This step is applied only to groups of pixels having area
#' greater or equal to \code{minArea}. Pixels belonging to the created buffers
#' are considered invali. In the second step all pixels in the
#' \code{invalidValues} range are marked as invalid. The final mask marks pixels
#' as valid if they weren't marked invalid on any any of steps.
#' @param tiles a data frame describing tiled images obtained from \code{\link{retile}}
#' @param tmpDir a directory for temporary files
#' @param minArea min \code{bufferedPixels} group area to include the area in the buffering step (see the description)
#' @param bufferSize size (in pixels) of a buffer created along areas having \code{bufferedPixels} values
#' @param invalidValues a set of values in the S2's SCL file considered invalid
#' @param bufferedValues a set of values in th2 S2's SCL file processed in the buffering step (see the description)
#' @return data frame describing created masks
#' @import dplyr
#' @export
prepareMasks = function(tiles, tmpDir, minArea = 25L, bufferSize = 10L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = c(3L, 8L:10L)) {
  # integer arithmetic is much faster
  minArea = as.integer(minArea)
  bufferSize = as.integer(bufferSize)
  invalidValues = as.integer(invalidValues)
  bufferedValues = as.integer(bufferedValues)

  masks = tiles %>%
    dplyr::filter(band == 'SCL') %>%
    dplyr::group_by(date, tile) %>%
    do({
      mask = raster::raster(.$tileFile)

      buffered = raster::getValues(mask)
      buffered = as.integer(buffered %in% bufferedValues)
      buffered = matrix(buffered, nrow = raster::nrow(mask), ncol = raster::ncol(mask))
      segments = mmand::components(buffered, mmand::shapeKernel(c(3L, 3L), type = 'diamond'))
      area = tabulate(segments)
      exclude = segments %in% which(area < minArea)
      buffered[exclude] = 0L

      # buffer with gdal_proximity cause it's 100 times faster then mmand::dilate() for large kernels
      tmp = raster::raster(mask)
      tmp = raster::setValues(tmp, as.vector(buffered))
      tmpFileIn = paste0(tmpDir, '/', .$date, '_CLOUDS_', .$tile, '.tif')
      raster::writeRaster(tmp, tmpFileIn, overwrite = TRUE, datatype = 'INT1U', NAflag = 255L)
      tmpFileOut = paste0(tmpDir, '/', .$date, '_BUFFERED_', .$tile, '.tif')
      command = sprintf('gdal_proximity.py %s %s -ot Byte -maxdist 10 -distunits PIXEL -fixed-buf-val 1 -values 1 -nodata 2', tmpFileIn, tmpFileOut)
      system(command, ignore.stdout = TRUE)
      buffered = raster::getValues(raster::raster(tmpFileOut))
      unlink(c(tmpFileIn, tmpFileOut))

      invalid = raster::getValues(mask)
      invalid = 255L * as.integer(invalid %in% invalidValues | is.na(invalid) | buffered < 2L)

      mask = raster::setValues(mask, invalid)
      tileFile = paste0(dirname(.$tileFile), '/', .$date, '_CLOUDMASK_', .$tile, '.tif')
      raster::writeRaster(mask, tileFile, overwrite = TRUE, datatype = 'INT1U', NAflag = 255L, options = 'COMPRESS=DEFLATE')

      dplyr::data_frame(band = 'CLOUDMASK', tileFile = tileFile)
    }) %>%
    dplyr::ungroup()

  return(masks)
}
