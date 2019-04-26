#' Generates EQUI7 tiles
#' @param images a data frame decscribing raw images to be retiled obtained with
#'   \code{\link{getImages}}
#' @param targetDir a directory where tiles should be saved (a separate
#'   subdirectory for each tile will be created)
#' @param gridFile a file providing a tiling grid (in any file format supported
#'   by the \code{\link[sf]{read_sf}}). All features have to have a \code{TILE}
#'   attribute denoting the tile name. The tiles projection will follow the grid
#'   file projection.
#' @param tmpDir a directory for temporary files
#' @param method resampling method (near, bilinear, cubic, cubicspline, lanczos,
#'   average, mode, max, min, med, q1, q3 - see gdalwarp doc)
#' @return data frame describing created tiles
#' @import dplyr
#' @export
prepareTiles = function(images, targetDir, gridFile, tmpDir, method = 'bilinear') {
  options(scipen = 100)
  if (!dir.exists(tmpDir)) {
    dir.create(tmpDir, recursive = TRUE)
  }

  noData = dplyr::data_frame(
    band = c(sprintf('B%02d', 1:12), 'B8A', 'AOT', 'CLD', 'DEM', 'PVI', 'SCL', 'SNW', 'TCI', 'VIS', 'WVP', 'albedo', 'FAPAR', 'FCOVER', 'LAI'),
    nodata = c(rep(0, 22), 65535, rep(32767, 3))
  )
  grid = sf::read_sf(gridFile)
  projection = sf::st_crs(grid)$proj4string
  gridBbox = dplyr::data_frame(
    tile = grid$TILE,
    bbox = purrr::map(grid$geometry, sf::st_bbox)
  ) %>%
    dplyr::mutate(bbox = purrr::map_chr(bbox, paste, collapse = ' '))

  # reproject
  imgs = images %>%
    dplyr::inner_join(noData) %>%
    dplyr::group_by(date, band, utm, file) %>%
    dplyr::mutate(
      equi7File = path.expand(paste0(tmpDir, '/', basename(file))),
    ) %>%
    dplyr::mutate(
      command = paste('gdalwarp -overwrite -tr 10.0 10.0 -r ', dplyr::if_else(band %in% 'SCL', 'near', method), ' -srcnodata', nodata, '-t_srs', paste0('"', projection, '"'), paste0('"', path.expand(file), '"'), paste0('"', equi7File, '"'))
    )
  imgs = imgs %>%
    dplyr::group_by(date, band, utm, file, equi7File) %>%
    dplyr::do({
      system(.$command, ignore.stdout = TRUE)
      dplyr::data_frame(geometry = .$geometry)
    }) %>%
    dplyr::ungroup() %>%
    dplyr::select(-file)

  # map images to grid tiles
  tiles = imgs %>%
    dplyr::group_by(date, band, equi7File) %>%
    dplyr::mutate(tile = list(grid$TILE[sf::st_intersects(grid, geometry[[1]], sparse = FALSE)])) %>%
    tidyr::unnest(tile) %>%
    dplyr::group_by(date, band, tile) %>%
    dplyr::summarize(
      inputFiles = paste0('"', equi7File, '"', collapse = ' ')
    ) %>%
    dplyr::inner_join(gridBbox) %>%
    dplyr::mutate(
      tileFile = sprintf('%s/%s/%s_%s_%s.tif', targetDir, tile, date, band, tile)
    ) %>%
    dplyr::mutate(command = paste('gdalwarp -overwrite -co "COMPRESS=DEFLATE" -te', bbox, inputFiles, tileFile)) %>%
    dplyr::select(-inputFiles, -bbox)

  # create target directory structure
  for (i in unique(dirname(tiles$tileFile))) {
    dir.create(i, recursive = TRUE, showWarnings = FALSE)
  }

  # retile
  tiles = tiles %>%
    dplyr::group_by(date, band, tile, tileFile) %>%
    dplyr::do({
      system(.$command, ignore.stdout = TRUE)
      dplyr::tibble(success = TRUE)
    }) %>%
    dplyr::select(-success)

  unlink(imgs$equi7File)

  return(tiles)
}
