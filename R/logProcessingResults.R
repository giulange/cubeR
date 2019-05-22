logProcessingResults = function(results, startTime) {
  if (!'processed' %in% names(results)) {
    results$processed = FALSE
  }
  t = as.numeric(Sys.time()) - as.numeric(startTime)
  results = results %>%
    dplyr::mutate(
      ok = file.exists(.data$tileFile)
    ) %>%
    dplyr::mutate(
      processed = .data$ok & dplyr::coalesce(.data$processed, FALSE)
    )
  t = min(options()$cores, sum(results$processed)) * t / sum(results$processed)
  cat(sprintf('%d/%d/%d\ttotal/ok/processed\t%s\t%f\n', nrow(results), sum(results$ok), sum(results$processed), Sys.time(), t))
}
