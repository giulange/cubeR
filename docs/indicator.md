#### indicator.R

Technically it is a wrapper for the [gdal_calc](https://gdal.org/programs/gdal_calc.html) taking care of running it in parallel and some data preparation steps.

Used to compute indicators which can be expressed (and effectively computed) using a single numpy expression.

##### Command line arguments

A standard set of `configFilePath`, `regionName`, `startDate` and `endDate`.

##### Data input/output

Reads data from the `rawDir` and stores results into the `rawDir`.

##### Performance

Depending on the `equation` complexity (see the configuration section below) the performance bottleneck may be either storage speed (simple equations) or CPU (complex ones).

##### Configuration

* `indicatorSkipExisting` allowing to skip computations of already existing output images.
* `indicatorIndicators` configuration property being a list of indicators to be computed. Each indicator is described by:
    * `bandName` output band/indicator name, e.g. `NDVI`.
    * `resolution` output data resolution. If some input rasters are in a different resolution, they will be automatically resampled.
    * `mask` name of a band to be used as a valid pixels mask.
    * `factor` output data scalling factor. Output data are saved using the 2B integer type (values ranging from -32768 to 32767). The `factor` parameter allows to rescale values coming from the `equation` computations into this range, e.g. for NDVI `10000` is a good `factor`.
    * `bands` list of input bands/indicators. Should be a named vector with every band/indicator denoted by a single capital letter, e.g. `c('A' = 'B04', 'B' = 'B08')`.
    * `equation` a numpy equation computing the indicator. Remember that:
        * If input data are integers you may need to cast the to floats to avoid strange results (e.g. getting only value of 0 while computing an NDVI), e.g. `(A.astype(float) - B) / (+ A + B)`.
        * Make sure you will never divide by zero. Add a neglectably small constant when needed, e.g. `'(A.astype(float) - B) / (0.0000001 + A + B)`.

A complete configuration for computing an NDVI (at a 10 m resolution and using a mask named `CLOUDMASK`) looks as follows:
```r
indicatorSkipExisting = TRUE
indicatorIndicators = list(
  list(bandName = 'NDVI',  resolution = 10, mask = 'CLOUDMASK', factor = 10000, bands = c('A' = 'B04', 'B' = 'B08'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)')
)
```

