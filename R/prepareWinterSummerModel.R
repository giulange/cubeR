#' Computes the winter/summer crops classification model
#' @param tilesRaw images data frame with images list obtained form
#'   \code{\link{getImages}}
#' @param periodsDir directory containing periods-level rasters
#' @param tilesDir directory containing tiles-level rasters
#' @param targetDir directory storing computed model results
#' @param tmpDir directory for temporary files
#' @param gridFile path to the file storing target grid
#' @param regionFile path to the file storing geometry of region of interest
#'   (lcFile and climateFiles are cut to this extent to minimize the amount of
#'   processing)
#' @param lcFile path to the land cover map file
#' @param climateFiles vector of file paths storing climate data to be used in
#'   the model
#' @param doyBand name of the band providing day of a year with a maximum NDVI
#' @param ndviMaxBand name of the band providing maximum yearly NDVI value
#' @param modelName name of the model - output data are organized according to
#'   the model name
#' @param ndviMin minimum NDVI value over a year for a pixel to be included in
#'   the model calibration
#' @param method resampling method used to reproject other data to the climate
#'   data projection and resolution (near, bilinear, cubic, cubicspline,
#'   lanczos, average, mode, max, min, med, q1, q3 - see gdalwarp doc)
#' @param skipExisting should already existing data be skipped?
#' @param gdalOpts additional gdalwarp options, e.g. enabling output file
#'   compression or multithreading
#' @return data frame with paths to files storing computed models
#' @import dplyr
#' @import foreach
#' @export
prepareWinterSummerModel = function(tilesRaw, periodsDir, tilesDir, targetDir, tmpDir, gridFile, regionFile, lcFile, climateFiles, doyBand, ndviMaxBand, modelName, ndviMin, method, skipExisting = TRUE, gdalOpts = '') {
  # extent
  tmpFile = raster::raster(climateFiles[1])
  res = paste(raster::res(tmpFile), collapse = ' ')
  proj = raster::projection(tmpFile)
  extent = sf::read_sf(regionFile, quiet = TRUE) %>%
    sf::st_transform(proj) %>%
    sf::st_bbox() %>%
    paste0(collapse = ' ')

  commands = character()
  toRemove = character()

  # climate
  if (is.null(names(climateFiles))) {
    names(climateFiles) = paste0('CLIM', seq_along(climateFiles))
  }
  climateFilesIn = climateFiles
  climateFilesOut = getTilePath(targetDir, modelName, '', names(climateFiles))
  createDirs(climateFilesOut)
  for (i in seq_along(climateFilesIn)) {
    outFile = climateFilesOut[i]
    tmpFile = paste0(tmpDir, '/', basename(outFile))
    toRemove = c(toRemove, tmpFile)
    command = sprintf('gdalwarp %s -q -overwrite -te %s -tr %s -r bilinear %s %s && mv %s %s', gdalOpts, extent, res, shQuote(climateFilesIn[i]), shQuote(tmpFile), shQuote(tmpFile), shQuote(outFile))
    commands = c(commands, command)
    unlink(outFile)
  }

  # LC
  lcFileOut = getTilePath(targetDir, modelName, '', 'LC')
  if (!skipExisting | !file.exists(lcFileOut)) {
    createDirs(lcFileOut)
    tmpFile = paste0(tmpDir, '/', basename(lcFileOut))
    toRemove = c(toRemove, tmpFile)
    command = sprintf('gdalwarp %s -q -overwrite -te %s -tr %s -t_srs %s -r near %s %s && mv %s %s', gdalOpts, extent, res, shQuote(proj), lcFile, shQuote(tmpFile), shQuote(tmpFile), shQuote(lcFileOut))
    commands = c(commands, command)
    unlink(lcFileOut)
  }

  # doyMaxNdvi & ndviMax
  tiles = tilesRaw %>%
    imagesToPeriods('1 year', periodsDir, c(doyBand, ndviMaxBand)) %>%
    mapTilesGrid(gridFile, regionFile) %>%
    dplyr::select(.data$period, .data$band, .data$tile) %>%
    dplyr::distinct() %>%
    dplyr::mutate(
      tileFile = getTilePath(tilesDir, .data$tile, .data$period, .data$band),
      outFile = getTilePath(targetDir, modelName, .data$period, .data$band)
    ) %>%
    dplyr::group_by(.data$band, .data$period, .data$outFile) %>%
    tidyr::nest()
  createDirs(tiles$outFile)
  for (i in seq_along(tiles$band)) {
    if (!skipExisting | !file.exists(tiles$outFile[i])) {
      outFile = tiles$outFile[i]
      tmpFile = paste0(tmpDir, '/', basename(outFile))
      tmpFileVrt = paste0(tmpFile, '.vrt')
      tmpFileVrtList = paste0(tmpFile, '.vrtlist')
      writeLines(tiles$data[[i]]$tileFile, tmpFileVrtList)
      toRemove = c(toRemove, c(tmpFile, tmpFileVrt, tmpFileVrtList))
      command1 = sprintf('gdalbuildvrt -q -input_file_list %s %s', tmpFileVrtList, tmpFileVrt)
      command2 = sprintf('gdalwarp %s -q -overwrite -te %s -tr %s -t_srs %s -r %s %s %s', gdalOpts, extent, res, shQuote(proj), shQuote(method), shQuote(tmpFileVrt), shQuote(tmpFile))
      command3 = sprintf('mv %s %s', shQuote(tmpFile), shQuote(outFile))
      commands = c(commands, paste0(command1, ' && ', command2, ' && ', command3))
      unlink(outFile)
    }
  }

  # preprocess in parallel
  foreach(command = commands) %dopar% {
    system(command)
  }
  unlink(toRemove)

  # model
  lcv   = raster::getValues(raster::raster(lcFileOut))
  mask = !is.na(lcv) & lcv >= 200 & lcv < 300
  climv = matrix(NA_integer_, nrow = length(lcv), ncol = length(climateFilesOut))
  colnames(climv) = names(climateFiles)
  for (i in seq_along(climateFilesOut)) {
    climv[, i] = raster::getValues(raster::raster(climateFilesOut[i]))
    mask = mask & !is.na(climv[, i])
  }
  periods = tiles %>%
    dplyr::group_by(.data$period) %>%
    dplyr::select(.data$period, .data$band, .data$outFile) %>%
    tidyr::spread('band', 'outFile')
  results = foreach(period = split(periods, seq_along(periods$period)), .combine = bind_rows) %dopar% {
    modelFile = getTilePath(targetDir, modelName, period$period, 'MODEL', ext = 'RData')
    coefFile = getTilePath(targetDir, modelName, period$period, 'COEF', ext = 'csv')
    result =     dplyr::tibble(
      period = period$period,
      coefFile = coefFile,
      modelFile = modelFile,
      processed = FALSE
    )
    if (!file.exists(modelFile) | !file.exists(coefFile) | skipExisting) {
      unlink(c(modelFile, coefFile))

      ndviv = raster::getValues(raster::raster(unlist(period[, ndviMaxBand])))
      doyv  = raster::getValues(raster::raster(unlist(period[, doyBand])))
      tileMask = mask & !is.na(doyv) & !is.na(ndviv) & ndviv >= ndviMin
      data = dplyr::tibble(doy = doyv[tileMask]) %>%
        dplyr::bind_cols(climv[tileMask, ] %>% as_tibble())
      frml = paste0('doy ~ ', paste0(names(climateFiles), collapse = ' + '))
      model = stats::lm(frml, data = data)

      param = dplyr::tibble(
        coef = tolower(gsub('[()]', '', names(stats::coef(model)))),
        value = as.numeric(stats::coef(model))
      )
      utils::write.csv(param, coefFile, row.names = FALSE, na = '')

      save(period, model, file = modelFile)

      result$processed = TRUE
    }
    result
 }
  return(results)
}

