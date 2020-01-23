library(dplyr)
library(ggplot2)
library(randomForest)
library(mlr3)
library(mlr3learners)
library(mlr3viz)
library(mlr3filters)
library(mlr3tuning)
library(paradox)
future::plan('multiprocess', workers = 6)

load('../data/shapes/lucas/extracted_FR-AU_2018.RData')
data = as_tibble(data) %>% select(-geometry)
data = data[rowSums(is.na(data)) < ncol(data) - 7, ]
lucas = sf::read_sf('../data/shapes/lucas/EU_2018_190611_CPRNC_G_3035_LAEAgridID_QB_NDVI_IMP2015_CLC2018_dec.shp')[, 1:98] %>% rename(point_id = POINT_I) %>% sf::st_transform(sf::st_crs(4326))
mapping = openxlsx::read.xlsx('../data/shapes/lucas/LUCAS crop types.xlsx')
lucas = lucas %>% left_join(mapping)
names(lucas) = tolower(names(lucas))
lucas = lucas %>% inner_join(data)
names(lucas) = tolower(names(lucas))
rm(data)
sf::st_write(lucas, '../data/shapes/lucas/lucas_with_extracted.geojson')
names(lucas) = gsub('-', '.', names(lucas))
tibble(na = 100 * rowSums(is.na(lucas)) / 204) %>% ggplot(aes(x = na)) + geom_histogram() + ggtitle('number of variables with a given percentage of missing values')

dataWs = lucas %>% as_tibble() %>% select(-geometry) %>% filter(!is.na(winter))
nas = tibble(
  col = names(dataWs),
  sat = !names(dataWs) %in% names(dataWs)[1:107],
  pna = 100 * colSums(is.na(dataWs)) / nrow(dataWs)
) %>%
  mutate(
    month = if_else(grepl('-[0-9][0-9]m1', col), suppressWarnings(as.integer(sub('^.*-([0-9]+)m1$', '\\1', col))), NA_integer_),
  ) %>%
  mutate(
    month = if_else(sat & grepl('y1$', col), 0L, month)
  )
tibble(na = 100 * colSums(is.na(dataWs)) / nrow(dataWs)) %>% ggplot(aes(x = na)) + geom_histogram() + ggtitle('number of variables with a given percentage of missing values')
### BASE MODEL
100 * table(dataWs$winter, dataWs$ws_2018y1) / nrow(dataWs) # 68% of correct classifications - not so bad for such a naive model
# data
dataWs$winterF = factor(dataWs$winter)
colsBasic = c('winterF', 'doymaxndvi2_2018y1', 'rain_1900.01.01', 'temp_1900.01.01')
colsYearly = c('winterF', 'doymaxndvi2_2018y1', 'rain_1900.01.01', 'temp_1900.01.01', 'ndvi2q05_2018y1', 'ndvi2q50_2018y1', 'ndvi2q98_2018y1', 'ndti2q05_2018y1', 'ndti2q50_2018y1', 'ndti2q98_2018y1', 'mndwi2q05_2018y1', 'mndwi2q50_2018y1', 'mndwi2q98_2018y1', 'ndbi2q05_2018y1', 'ndbi2q50_2018y1', 'ndbi2q98_2018y1', 'bsi2q05_2018y1', 'bsi2q50_2018y1', 'bsi2q98_2018y1', 'blfei2q05_2018y1', 'blfei2q50_2018y1', 'blfei2q98_2018y1')
colsMonthlyMayAug = c('winterF', 'rain_1900.01.01', 'temp_1900.01.01', 'lai2_2018.05m1', 'lai2_2018.06m1', 'lai2_2018.07m1', 'lai2_2018.08m1', 'ndvi2_2018.05m1', 'ndvi2_2018.06m1', 'ndvi2_2018.07m1', 'ndvi2_2018.08m1', 'fapar2_2018.05m1', 'fapar2_2018.06m1', 'fapar2_2018.07m1', 'fapar2_2018.08m1', 'fcover2_2018.05m1', 'fcover2_2018.06m1', 'fcover2_2018.07m1', 'fcover2_2018.08m1')
colsAll = c('winterF', 'doymaxndvi2_2018y1', 'rain_1900.01.01', 'temp_1900.01.01', 'ndvi2q05_2018y1', 'ndvi2q50_2018y1', 'ndvi2q98_2018y1', 'ndti2q05_2018y1', 'ndti2q50_2018y1', 'ndti2q98_2018y1', 'mndwi2q05_2018y1', 'mndwi2q50_2018y1', 'mndwi2q98_2018y1', 'ndbi2q05_2018y1', 'ndbi2q50_2018y1', 'ndbi2q98_2018y1', 'bsi2q05_2018y1', 'bsi2q50_2018y1', 'bsi2q98_2018y1', 'blfei2q05_2018y1', 'blfei2q50_2018y1', 'blfei2q98_2018y1', 'lai2_2018.05m1', 'lai2_2018.06m1', 'lai2_2018.07m1', 'lai2_2018.08m1', 'ndvi2_2018.05m1', 'ndvi2_2018.06m1', 'ndvi2_2018.07m1', 'ndvi2_2018.08m1', 'fapar2_2018.05m1', 'fapar2_2018.06m1', 'fapar2_2018.07m1', 'fapar2_2018.08m1', 'fcover2_2018.05m1', 'fcover2_2018.06m1', 'fcover2_2018.07m1', 'fcover2_2018.08m1')
dataBasic         = TaskClassif$new(id = 'WinterSummerBasic',         target = 'winterF', backend = dataWs %>% select(!!colsBasic) %>% filter(rowSums(is.na(.)) == 0))
dataYearly        = TaskClassif$new(id = 'WinterSummerYearly',        target = 'winterF', backend = dataWs %>% select(!!colsYearly) %>% filter(rowSums(is.na(.)) == 0))
dataMonthlyMayAug = TaskClassif$new(id = 'WinterSummerMonthlyMayAug', target = 'winterF', backend = dataWs %>% select(!!colsMonthlyMayAug) %>% filter(rowSums(is.na(.)) == 0))
dataAll           = TaskClassif$new(id = 'WinterSummerAll',           target = 'winterF', backend = dataWs %>% select(!!colsAll) %>% filter(rowSums(is.na(.)) == 0))
validCount = tibble(
  task_id = c('WinterSummerBasic', 'WinterSummerYearly', 'WinterSummerMonthlyMayAug', 'WinterSummerAll'),
  valid_obs = c(dataBasic$nrow, dataYearly$nrow, dataMonthlyMayAug$nrow, dataAll$nrow) / nrow(dataWs)
)
# learners
learnForest = lrn('classif.ranger', predict_type = 'prob')
learnBayes = lrn('classif.naive_bayes', predict_type = 'prob')
learnLog = lrn('classif.log_reg', predict_type = 'prob')
# sampler
sampler = rsmp('cv', folds = 5)
# design
design = benchmark_grid(
  tasks = list(dataBasic, dataYearly, dataMonthlyMayAug, dataAll),
  learners = list(learnForest, learnBayes, learnLog),
  resamplings = sampler
)
results = benchmark(design)
results$aggregate(list(msr('classif.acc'))) %>% inner_join(validCount) %>% arrange(desc(classif.acc))
autoplot(results, type = 'roc')
results$resample_result(1)$predictions()
modelsWs = list(
  # prefer learnForest because it's faster, the accuracy is only marginally lower and svm caused troubles with predictions on full raster data
  list(learner = learnForest$train(dataAll), cols = colsAll[-1], levels = levels(dataWs$winterF)),
  list(learner = learnForest$train(dataYearly), cols = colsYearly[-1], levels = levels(dataWs$winterF))
)
save(modelsWs, file = '/eodc/private/boku/ACube2/models/ML/ws.RData')

# all classes
dataCl = lucas %>% as_tibble() %>% select(-geometry) %>% filter(!is.na(classname))
dataCl$classnameF = factor(dataCl$classname)
dataCl %>% group_by(classname) %>% summarize(n = n(), p = 100 * n() / nrow(.)) %>% arrange(n) %>% print(n = 100)
dataCl = dataCl %>% group_by(classname) %>% filter(n() >= 100) %>% ungroup()
dataCl$classnameF = factor(as.character(dataCl$classname))
colsBasic = c('classnameF', 'doymaxndvi2_2018y1', 'rain_1900.01.01', 'temp_1900.01.01')
colsYearly = c('classnameF', 'doymaxndvi2_2018y1', 'rain_1900.01.01', 'temp_1900.01.01', 'ndvi2q05_2018y1', 'ndvi2q50_2018y1', 'ndvi2q98_2018y1', 'ndti2q05_2018y1', 'ndti2q50_2018y1', 'ndti2q98_2018y1', 'mndwi2q05_2018y1', 'mndwi2q50_2018y1', 'mndwi2q98_2018y1', 'ndbi2q05_2018y1', 'ndbi2q50_2018y1', 'ndbi2q98_2018y1', 'bsi2q05_2018y1', 'bsi2q50_2018y1', 'bsi2q98_2018y1', 'blfei2q05_2018y1', 'blfei2q50_2018y1', 'blfei2q98_2018y1')
colsMonthlyMayAug = c('classnameF', 'rain_1900.01.01', 'temp_1900.01.01', 'lai2_2018.05m1', 'lai2_2018.06m1', 'lai2_2018.07m1', 'lai2_2018.08m1', 'ndvi2_2018.05m1', 'ndvi2_2018.06m1', 'ndvi2_2018.07m1', 'ndvi2_2018.08m1', 'fapar2_2018.05m1', 'fapar2_2018.06m1', 'fapar2_2018.07m1', 'fapar2_2018.08m1', 'fcover2_2018.05m1', 'fcover2_2018.06m1', 'fcover2_2018.07m1', 'fcover2_2018.08m1')
colsAll = c('classnameF', 'doymaxndvi2_2018y1', 'rain_1900.01.01', 'temp_1900.01.01', 'ndvi2q05_2018y1', 'ndvi2q50_2018y1', 'ndvi2q98_2018y1', 'ndti2q05_2018y1', 'ndti2q50_2018y1', 'ndti2q98_2018y1', 'mndwi2q05_2018y1', 'mndwi2q50_2018y1', 'mndwi2q98_2018y1', 'ndbi2q05_2018y1', 'ndbi2q50_2018y1', 'ndbi2q98_2018y1', 'bsi2q05_2018y1', 'bsi2q50_2018y1', 'bsi2q98_2018y1', 'blfei2q05_2018y1', 'blfei2q50_2018y1', 'blfei2q98_2018y1', 'lai2_2018.05m1', 'lai2_2018.06m1', 'lai2_2018.07m1', 'lai2_2018.08m1', 'ndvi2_2018.05m1', 'ndvi2_2018.06m1', 'ndvi2_2018.07m1', 'ndvi2_2018.08m1', 'fapar2_2018.05m1', 'fapar2_2018.06m1', 'fapar2_2018.07m1', 'fapar2_2018.08m1', 'fcover2_2018.05m1', 'fcover2_2018.06m1', 'fcover2_2018.07m1', 'fcover2_2018.08m1')
dataBasic         = TaskClassif$new(id = 'cropBasic',         target = 'classnameF', backend = dataCl %>% select(!!colsBasic) %>% filter(rowSums(is.na(.)) == 0))
dataYearly        = TaskClassif$new(id = 'cropYearly',        target = 'classnameF', backend = dataCl %>% select(!!colsYearly) %>% filter(rowSums(is.na(.)) == 0))
dataMonthlyMayAug = TaskClassif$new(id = 'cropMonthlyMayAug', target = 'classnameF', backend = dataCl %>% select(!!colsMonthlyMayAug) %>% filter(rowSums(is.na(.)) == 0))
dataAll           = TaskClassif$new(id = 'cropAll',           target = 'classnameF', backend = dataCl %>% select(!!colsAll) %>% filter(rowSums(is.na(.)) == 0))
validCount = tibble(
  task_id = c('cropBasic', 'cropYearly', 'cropMonthlyMayAug', 'cropAll'),
  valid_obs = c(dataBasic$nrow, dataYearly$nrow, dataMonthlyMayAug$nrow, dataAll$nrow) / nrow(dataCl)
)
# learners
learnForest = lrn('classif.ranger', predict_type = 'prob')
learnBayes = lrn('classif.naive_bayes', predict_type = 'prob')
learnRpart = lrn('classif.rpart', predict_type = 'prob')
learnSvm = lrn('classif.svm', predict_type = 'prob')
learnQda = lrn('classif.qda', predict_type = 'prob')
learnGlmnet = lrn('classif.glmnet', predict_type = 'prob')
learnKknn = lrn('classif.kknn', predict_type = 'prob')
learnLda = lrn('classif.lda', predict_type = 'prob')
learnXgboost = lrn('classif.xgboost', predict_type = 'prob')
# design & estimation
design = benchmark_grid(
  tasks = list(dataBasic, dataYearly, dataMonthlyMayAug, dataAll),
  learners = list(learnForest, learnBayes, learnRpart, learnSvm, learnQda, learnGlmnet, learnKknn, learnLda, learnXgboost),
  resamplings = rsmp('cv', folds = 5)
)
results = benchmark(design)
save(results, file = 'vignettes/lucas_analyze_models_class.RData')
results$aggregate(list(msr('classif.acc'))) %>% inner_join(validCount) %>% arrange(desc(classif.acc), desc(valid_obs))
modelsCl = list(
  # prefer learnForest because it's faster, the accuracy is only marginally lower and svm caused troubles with predictions on full raster data
  list(learner = learnForest$train(dataAll), cols = colsAll[-1], levels = levels(dataCl$classnameF)),
  list(learner = learnForest$train(dataYearly), cols = colsYearly[-1], levels = levels(dataCl$classnameF))
)
save(modelsCl, file = '/eodc/private/boku/ACube2/models/ML/cl.RData')

# hyperparameters tuning
tunerForest = AutoTuner$new(
  learner = learnForest,
  resampling = rsmp('cv', folds = 3),
  measures = msr('classif.acc'),
  tune_ps = ParamSet$new(list(
    ParamInt$new('num.trees', lower = 250, upper = 750),
    ParamInt$new('min.node.size', lower = 1, upper = 10),
    ParamFct$new('splitrule', levels = c('gini', 'extratrees'))
  )),
  terminator = term('model_time', secs = 3600),
  tuner = tnr('random_search')
)
tunerSvm = AutoTuner$new(
  learner = learnSvm,
  resampling = rsmp('cv', folds = 3),
  measures = msr('classif.acc'),
  tune_ps = ParamSet$new(list(
    ParamFct$new('kernel', levels = c('linear', 'polynomial', 'radial', 'sigmoid'))
  )),
  terminator = term('model_time', secs = 3600),
  tuner = tnr('random_search')
)
design = benchmark_grid(
  tasks = list(dataYearly, dataAll),
  learners = list(tunerForest, tunerSvm),
  resamplings = rsmp('cv', folds = 5)
)
results2 = benchmark(design)
# improvment on a 4th digit - negligible
results2$aggregate(list(msr('classif.acc'))) %>% inner_join(validCount) %>% arrange(desc(valid_obs), desc(classif.acc))
results$aggregate(list(msr('classif.acc'))) %>% inner_join(validCount) %>% filter(learner_id %in% c('classif.ranger', 'classif.svm') & task_id %in% c('cropYearly', 'cropAll')) %>% arrange(desc(valid_obs), desc(classif.acc))
