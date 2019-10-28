library(dplyr)
library(ggplot2)
Sys.setlocale("LC_TIME", "C")
lc   = raster::raster('~/roboty/BOKU/cube/data/shapes/wc2.0_2.5m_bio/CLC2018_MOD_30s.tif')
temp = raster::raster('~/roboty/BOKU/cube/data/shapes/wc2.0_2.5m_bio/eu_wc2.0_bio_01_30s.tif')
rain = raster::raster('~/roboty/BOKU/cube/data/shapes/wc2.0_2.5m_bio/eu_wc2.0_bio_10_30s.tif')
doy  = raster::raster('~/roboty/BOKU/cube/data/shapes/wc2.0_2.5m_bio/2018y1_DOYMAXNDVI2MOD_30s.tif')
ndvi = raster::raster('~/roboty/BOKU/cube/data/shapes/wc2.0_2.5m_bio/2018y1_NDVI2q98MOD_30s.tif')

lcv  = raster::getValues(lc)
ndviv = raster::getValues(ndvi)
tempv = raster::getValues(temp)
rainv = raster::getValues(rain)
doyv = raster::getValues(doy)
mask = !is.na(lcv) & lcv >= 200 & lcv < 300 & !is.na(ndviv) & ndviv >= 5000 & !is.na(tempv) & !is.na(rainv) & !is.na(doyv)
100 * table(mask) / length(mask)
d = tibble(
  lc   = factor(lcv[mask]),
  temp = tempv[mask],
  rain = rainv[mask],
  doy  = doyv[mask],
  ndvi = ndviv[mask]
)
d = d %>%
  mutate(
    tempg = as.integer(10 * (temp - min(temp, na.rm = T)) / (0.001 + max(temp, na.rm = T) - min(temp, na.rm = T))),
    raing = as.integer(10 * (rain - min(rain, na.rm = T)) / (0.001 + max(rain, na.rm = T) - min(rain, na.rm = T))),
    doyg = as.integer(as.integer(doy / 5)),
    ndvig = as.integer(10 * (ndvi - min(ndvi, na.rm = T)) / (max(ndvi, na.rm = T) - min(ndvi, na.rm = T))),
    temps = (temp - mean(temp, na.rm = TRUE)) / sd(temp, na.rm = TRUE),
    rains = (rain - mean(rain, na.rm = TRUE)) / sd(rain, na.rm = TRUE),
    doys =  (doy - mean(doy, na.rm = TRUE)) / sd(doy, na.rm = TRUE),
    ndvis = (ndvi - mean(ndvi, na.rm = TRUE)) / sd(ndvi, na.rm = TRUE)
  )
templ = d %>%
  group_by(tempg) %>%
  summarize(templ = paste0(round(min(temp), 1), '-', round(max(temp), 1)))

m1 = lm(doy ~ temp + rain, data = d)
m2 = lm(doy ~ temp + rain, data = d %>% filter(as.character(lc) == '211'))
m3 = lm(doy ~ temp + rain, data = d %>% filter(doy > 30 & doy < 270))
m4 = lm(doy ~ temp + rain, data = d %>% filter(doy > 30 & doy < 270 & as.character(lc) == '211'))
d$ws1 = if_else(d$doy <= predict(m1, d), 'winter', 'summer')
d$ws2 = if_else(d$doy <= predict(m2, d), 'winter', 'summer')
d$ws3 = if_else(d$doy <= predict(m3, d), 'winter', 'summer')
d$ws4 = if_else(d$doy <= predict(m4, d), 'winter', 'summer')
lm(doy ~ temp + rain + ws1, data = d) %>% summary()
lm(doy ~ temp + rain + ws2, data = d) %>% summary()
lm(doy ~ temp + rain + ws3, data = d) %>% summary()
lm(doy ~ temp + rain + ws4, data = d) %>% summary()

ngroup = 5
k = kmeans(cbind(d$temps, d$rains), ngroup, nstart = 5)
d$k = rownames(fitted(k))
centers = k$centers[, 1:2] * matrix(c(rep(sd(d$temp), ngroup), rep(sd(d$rain), ngroup)), nrow = ngroup, ncol = 2) + matrix(c(rep(mean(d$temp), ngroup), rep(mean(d$rain), ngroup)), nrow = ngroup, ncol = 2)
colnames(centers) = c('templ', 'rainl')
centers = centers %>%
  round() %>%
  as_tibble() %>%
  mutate(k = rownames(k$centers)) %>%
  mutate(kl = sprintf('mean temp %02d°C\nmean rain %d mm (%s)', templ, rainl, k)) %>%
  arrange(templ, rainl)
100 * table(d$ws1, d$k) / nrow(d)
d %>%
  sample_frac(0.01) %>%
  left_join(centers) %>%
  rename(`climate group` = kl) %>%
  ggplot(aes(x = temp, y = rain, color = `climate group`)) +
  geom_jitter(alpha = 0.4) +
  ggtitle('Climate regions resulting from the k-means algorithm',  'applied to standardized values of average yearly temperatur and sum of precipitation')

d %>%
  rename(ws = ws1) %>%
  group_by(doyg, ws) %>%
  summarize(n = n()) %>%
  ungroup() %>%
  mutate(p = 100 * n / sum(n)) %>%
  mutate(doyg = as.Date(doyg * 5, origin = as.Date('2018-01-01'))) %>%
  rename(`crop type` = ws) %>%
  ggplot(aes(x = doyg, y = p, fill = `crop type`, group = `crop type`)) +
  geom_col(position = 'stack') +
  ylab('area percentage') +
  xlab('day of year with maximum NDVI') +
  scale_x_date(breaks = seq(as.Date('2018-01-01'), as.Date('2019-01-01'), '1 month'), labels = format(seq(as.Date('2018-01-01'), as.Date('2019-01-01'), '1 month'), '1st %b')) +
  ggtitle('Winter/summer classification results for year 2018')

d %>%
  rename(ws = ws2) %>%
  group_by(k, doyg, ws) %>%
  summarize(n = n()) %>%
  group_by(k) %>%
  mutate(p = 100 * n / sum(n)) %>%
  ungroup() %>%
  mutate(doyg = as.Date(doyg * 5, origin = as.Date('2018-01-01'))) %>%
  left_join(centers) %>%
  rename(`crop type` = ws) %>%
  ggplot(aes(x = doyg, y = p, fill = `crop type`, group = `crop type`)) +
  geom_col(position = 'stack') +
  facet_grid(kl ~ .) +
  ylab('area percentage') +
  xlab('day of year with maximum NDVI') +
  scale_x_date(breaks = seq(as.Date('2018-01-01'), as.Date('2019-01-01'), '1 month'), labels = format(seq(as.Date('2018-01-01'), as.Date('2019-01-01'), '1 month'), '1st %b')) +
  ggtitle('Classification results within four climate zones for year 2018', 'Climate zones created using k-means clustering on standardized yearly mean temperature and sum of precipitation')

c = m$coefficients
thv = c[1] + tempv * c['temp'] + rainv * c['rain']
th = raster::raster(ndvi)
th = raster::setValues(th, thv)
raster::writeRaster(th, '~/roboty/BOKU/cube/data/shapes/wc2.0_2.5m_bio/threshold_30s.tif', overwrite = TRUE, options = c("COMPRESS=DEFLATE", "TILED=YES", "BLOCKXSIZE=512", "BLOCKYSIZE=512"))
system(paste0('gdal_calc.py -A eu_wc2.0_bio_01_100m.tif -B eu_wc2.0_bio_10_100m.tif --calc "', c[1], ' + ', c['temp'], '*A + ', c['rain'], '*B" --type=Int16 --outfile=threshold_100m.tif --co="COMPRESS=DEFLATE" --co="TILED=YES" --co="BLOCKXSIZE=512" --co="BLOCKYSIZE=512"'))

kv = rep(NA_integer_, length(thv))
kv[mask] = as.integer(d$k)
kr = raster::raster(ndvi)
kr = raster::setValues(kr, kv)
raster::writeRaster(kr, '~/roboty/BOKU/cube/data/shapes/wc2.0_2.5m_bio/climate_30s.tif', overwrite = TRUE, datatype = 'INT1U', options = c("COMPRESS=DEFLATE", "TILED=YES", "BLOCKXSIZE=512", "BLOCKYSIZE=512"))

wsv = 1 + (doyv <= thv)
wsv[is.na(lcv) | lcv < 200 | lcv >= 300] = NA
ws = raster::raster(ndvi)
ws = raster::setValues(ws, wsv)
raster::writeRaster(ws, '~/roboty/BOKU/cube/data/shapes/wc2.0_2.5m_bio/wintersummer_30s.tif', overwrite = TRUE, datatype = 'INT1U', options = c("COMPRESS=DEFLATE", "TILED=YES", "BLOCKXSIZE=512", "BLOCKYSIZE=512"))
system('gdal_calc.py -A threshold_100m.tif -B 2018y1_DOYMAXNDVI2MOD_100m.tif -C CLC2018_100m.tif --calc "(C >= 200) * (C < 300) * (1 + (B <= A))" --type=Byte --NoDataValue=0 --outfile=wintersummer_MOD_100m.tif --co="COMPRESS=DEFLATE" --co="TILED=YES" --co="BLOCKXSIZE=512" --co="BLOCKYSIZE=512"')
system('gdal_calc.py -A threshold_100m.tif -B 2018y1_DOYMAXNDVI2LIN_100m.tif -C CLC2018_100m.tif --calc "(C >= 200) * (C < 300) * (1 + (B <= A))" --type=Byte --NoDataValue=0 --outfile=wintersummer_LIN_100m.tif --co="COMPRESS=DEFLATE" --co="TILED=YES" --co="BLOCKXSIZE=512" --co="BLOCKYSIZE=512"')
system('gdal_calc.py -A threshold_100m.tif -B 2018y1_DOYMAXNDVI2NEAR_100m.tif -C CLC2018_100m.tif --calc "(C >= 200) * (C < 300) * (1 + (B <= A))" --type=Byte --NoDataValue=0 --outfile=wintersummer_NEAR_100m.tif --co="COMPRESS=DEFLATE" --co="TILED=YES" --co="BLOCKXSIZE=512" --co="BLOCKYSIZE=512"')

# compare with the crop classification for Marchfeld
system('gdalwarp -co "COMPRESS=DEFLATE" -co "TILED=YES" -co "BLOCKXSIZE=512" -co "BLOCKYSIZE=512" -tr 100 -100 -t_srs EPSG:3035 -r near 2018_03_masked_on_INVEKOS1.tif 2018_03_masked_on_INVEKOS1_100m_.tif')
system('gdalwarp -te 4795404.655 2800547.271 4839504.655 2841747.271 -r near wintersummer_NEAR_100m.tif wintersummer_NEAR_masked_100m.tif')
system('gdal_calc.py -A 2018_03_masked_on_INVEKOS1_100m_.tif -B wintersummer_NEAR_masked_100m.tif --calc "A" --outfile 2018_03_masked_on_INVEKOS1_100m.tif --co COMPRESS=DEFLATE --co "TILED=YES" --co "BLOCKXSIZE=512" --co "BLOCKYSIZE=512" --overwrite
')
refv = raster::getValues(raster::raster('~/roboty/BOKU/cube/data/shapes/wc2.0_2.5m_bio/2018_03_masked_on_INVEKOS1_100m.tif'))
tv = raster::getValues(raster::raster('~/roboty/BOKU/cube/data/shapes/wc2.0_2.5m_bio/wintersummer_NEAR_masked_100m.tif'))
refmask = !is.na(refv) & refv == 3 # 3 - winter cereal
100 * table(tv[refmask], useNA = 'always') / sum(refmask)
