logProcessingResults = function(results) {
  if (!'processed' %in% names(results)) {
    results$processed = FALSE
  }
  results = results %>%
    dplyr::mutate(
      ok = file.exists(.data$tileFile)
    ) %>%
    dplyr::mutate(
      processed = .data$ok & dplyr::coalesce(.data$processed, FALSE)
    )
  cat(sprintf('%d/%d/%d\ttotal/ok/processed\t%s\n', nrow(results), sum(results$ok), sum(results$processed), Sys.time()))
}