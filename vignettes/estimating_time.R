args = c("vignettes/configZozlak.R", "zozlak", "alamakota", "AU_cube", "2018-05-01", "2018-05-31", "1 month", "NMAXNDVI")
names(args) = c('cfgFile', 'user', 'pswd', 'region', 'from', 'to')

library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
S2_initialize_user(args['user'], args['pswd'])
projection = sf::st_crs(sf::st_read(gridFile, quiet = TRUE))

roi = c('UK_cube', 'SZ_cube', 'SW_cube', 'SP_cube', 'SI_cube', 'RO_cube', 'PO_cube', 'PL_cube', 'NL_cube', 'MN_cube', 'MK_cube', 'MD_cube', 'LU_cube', 'LS_cube', 'LO_cube', 'LH_cube', 'LG_cube', 'LA_cube', 'IT_cube', 'IC_cube', 'HU_cube', 'HR_cube', 'GR_cube', 'GM_cube', 'FR_cube', 'FI_cube', 'EZ_cube', 'EN_cube', 'EI_cube', 'DA_cube', 'BU_cube', 'BK_cube', 'BE_cube', 'AU_cube', 'AL_cube')
stat = list()
ready = list()
for (i in seq_along(roi)) {
  cat(i, '\n')
  stat[[length(stat) + 1]] = S2_query_granule(atmCorr = TRUE, regionId = roi[i], dateMin = '2016-01-01', dateMax = '2018-12-31', cloudCovMin = 0, cloudCovMax = cloudCov * 100) %>%
    mutate(roi = roi[i])
  ready[[length(ready) + 1]] = getImages(roi[i], '2016-01-01', '2018-12-31', cloudCov, rawDir, projection, bands, args['user'], args['pswd'], FALSE) %>%
    mutate(roi = roi[i])
}
stat = bind_rows(stat)
ready = bind_rows(ready)
save(stat, ready, file = 'vignettes/estimating_time.RData')
stat = stat %>%
  select(granuleId, date, utm, orbit, cloudCov, roi) %>%
  mutate(date = substr(date, 1, 10))
ready = ready %>%
  select(granuleId, date, utm, orbit, cloudCov, roi) %>%
  distinct() %>%
  mutate(date = substr(date, 1, 10))

# NUMBER OF GRANULES PER CUBE PER YEAR
stat %>%
  mutate(year = substr(date, 1, 4)) %>%
  group_by(roi, year) %>%
  summarize(n = n_distinct(date, utm)) %>%
  arrange(roi, year) %>%
  tidyr::spread(year, n)
stat %>%
  mutate(year = substr(date, 1, 4)) %>%
  group_by(year) %>%
  summarize(n = n_distinct(date, utm)) %>%
  arrange(year) %>%
  tidyr::spread(year, n)

# MISSING GRANULES
ready2 = ready %>% select(date, utm, roi) %>% distinct()
stat2 = stat %>% select(date, utm, roi) %>% distinct()
anti_join(ready2, stat2) # should be empty
anti_join(stat2 %>% select(-roi) %>% distinct(), ready2 %>% select(-roi) %>% distinct()) %>%
  mutate(year = substr(date, 1, 4)) %>%
  group_by(year) %>%
  summarize(n = n())
anti_join(stat2, ready2) %>%
  mutate(year = substr(date, 1, 4)) %>%
  group_by(year, roi) %>%
  summarize(n = n()) %>%
  tidyr::spread(year, n)
