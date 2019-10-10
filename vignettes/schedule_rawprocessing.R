library(sentinel2)
library(dplyr)

date2months = function(x, k = 1) {
  return(as.integer(substr(x, 1, 4)) * 12 + floor(as.integer(substr(x, 6, 7)) / k) * k - 1)
}
months2date = function(x, k = 1) {
  return(sprintf('%04d-%02d', floor(x / 12), 1 + (x %% 12) * k))
}

S2_initialize_user('zozlak', 'alamakota')

maxGranules = 1 # per orbit
maxCc = 0.2
monthMin = date2months('2019-07') #min(g$month)
monthMax = date2months('2019-09') #max(g$month)

gCube = as.tbl(S2_query_granule(regionId = '%_cube', dateMin = paste0(months2date(monthMin), '-01'), dateMax = paste0(months2date(monthMax), '-01'))) %>%
  mutate(cube = TRUE) %>%
  select(granuleId, cube)
gAll = as.tbl(S2_query_granule(regionId = '%_cube', cloudCovMax = 100, dateMin = paste0(months2date(monthMin), '-01'), dateMax = paste0(months2date(monthMax), '-01')))
g = gAll %>%
  mutate(month = date2months(date)) %>%
  left_join(gCube)
save(g, file = 'all_granules.RData')

months = tibble(month = seq(monthMin, monthMax)) %>%
  left_join(g) %>%
  group_by(month, utm, orbit) %>%
  arrange(month, utm, orbit, cloudCov) %>%
  mutate(
    prob = 1 - cumprod(cloudCov / 100),
    n = row_number()
  )
# Here and now how many {month, utm tile, orbit} have data
months %>%
  summarize(passed = any(atmCorr > 0)) %>%
  group_by(passed) %>%
  summarize(n = n())
# How many {month, utm tile, orbit} can pass the minProb using no more then maxGranules?
months %>%
  summarize(passed = first(cloudCov) <= maxCc * 100) %>%
  group_by(passed) %>%
  summarize(n = n())
# How many additional granules have to be processed
months %>%
  filter((n <= maxGranules | !is.na(cube)) & cloudCov <= maxCc * 100) %>%
  group_by(atmCorr) %>%
  summarize(n = n())

### create ROIs

maxGranules = 1 # per orbit
maxCc = 0.2
monthMin = date2months('2019-07') #min(g$month)
monthMax = date2months('2019-09') #max(g$month)

months = tibble(month = seq(monthMin, monthMax)) %>%
  left_join(g) %>%
  group_by(month, utm, orbit) %>%
  arrange(month, utm, orbit, cloudCov) %>%
  mutate(n = row_number())
toAdd = months %>%
  filter(n <= maxGranules & cloudCov <= maxCc * 100 & is.na(cube) & atmCorr == 0) %>%
  mutate(bought = FALSE)
save(toAdd, file = '~/Pulpit/cube.RData')
load('~/Pulpit/cube.RData')
for (i in seq_along(toAdd$granuleId)) {
  if (!toAdd$bought[i]) {
    try({
      S2_buy_granule(toAdd$granuleId[i], 'always')
      toAdd$bought[i] = TRUE
    })
  }
  if (i %% 50 == 0) {
    cat(i, '\n')
    save(toAdd, file = '~/Pulpit/cube.RData')
  }
}
