#!/usr/bin/python3

import argparse
import datetime
import gdal
import logging
import math
import multiprocessing
import numpy
import os
import osgeo
import re
import sys

from numba import jit


parser = argparse.ArgumentParser()
parser.add_argument('--verbose', action='store_true')
parser.add_argument('--blockSize', type=int, default=512)
parser.add_argument('--gdalCacheSize', type=int, default=2147483648)
parser.add_argument('--nCores', type=int, default=8)
parser.add_argument('--lmbd', type=float, default=1)
parser.add_argument('--period', type=int, default=10)
parser.add_argument('--formatOptions', nargs='*', default=['COMPRESS=DEFLATE', 'TILED=YES', 'BLOCKXSIZE=512', 'BLOCKYSIZE=512'], help='output format options')
parser.add_argument('--algorithm', default='near', help='resampling algorithm to be used for the highest resolution')
parser.add_argument('--band', default='NDVI2')
parser.add_argument('--maskBand', default='CLOUDMASK2')
parser.add_argument('--nodataValue', default=32767)
parser.add_argument('--dataDir', default='/eodc/private/boku/ACube2/raw')
parser.add_argument('--geomCacheFile', default='cache.geojson')
parser.add_argument('--tmpDir', default='tmp')
parser.add_argument('shapeFileName')
parser.add_argument('dateFrom')
parser.add_argument('dateTo')
parser.add_argument('outputDir')
parser.add_argument('outputTileName')
args = parser.parse_args()

logging.basicConfig(stream=sys.stdout, level=logging.DEBUG if args.verbose else logging.INFO)

if args.gdalCacheSize is not None:
    gdal.SetCacheMax(args.gdalCacheSize)

### Read the input geometry
shpSrc   = osgeo.ogr.Open(args.shapeFileName)
layerSrc = shpSrc.GetLayer()
geomSrc  = None
for ftr in layerSrc:
    if geomSrc is None:
        geomSrc = ftr.GetGeometryRef()
    else:
        geomSrc = geomSrc.Union(ftr.GetGeometryRef())
geomSrc  = geomSrc.Clone()
prjSrc   = layerSrc.GetSpatialRef().Clone()
layerSrc = None
shpSrc   = None
# prepare a cutline geometry
fileCut    = os.path.join(args.tmpDir, 'geom.geojson')
driverCut  = osgeo.ogr.GetDriverByName('GeoJSON')
shpCut     = driverCut.CreateDataSource(fileCut)
layerCut   = shpCut.CreateLayer('cutline', prjSrc, geomSrc.GetGeometryType())
featureCut = osgeo.ogr.Feature(layerCut.GetLayerDefn())
featureCut.SetGeometry(geomSrc)
layerCut.CreateFeature(featureCut)
featureCut = None
layerCut   = None
shpCut     = None

### Maintain cache
if not os.path.exists(args.geomCacheFile):
    with open(args.geomCacheFile, 'w') as f:
        f.write('{"type": "FeatureCollection","features": []}')
shpCache   = osgeo.ogr.Open(args.geomCacheFile, 1)
layerCache = shpCache.GetLayer()
prjCache   = layerCache.GetSpatialRef()
# assure tile field exists
if layerCache.FindFieldIndex('tile', False) < 0:
    tileField = osgeo.ogr.FieldDefn('tile', osgeo.ogr.OFTString)
    layerCache.CreateField(tileField)
# find tiles missing in cache
utmsData   = os.listdir(args.dataDir)
tilesInCache = []
for ftr in layerCache:
    tilesInCache.append(ftr.GetField('tile'))
tilesToCache = set(os.listdir(args.dataDir)) - set(tilesInCache)
# iterate trough missing tiles
if len(tilesToCache) > 0:
    logging.info('Building cache for %d tiles' % len(tilesToCache))
layerDefCache = layerCache.GetLayerDefn()
n = 0
for tile in tilesToCache:
    n += 1
    logging.debug('  %s (%d/%d)' % (tile, n, len(tilesToCache)))

    for fl in os.scandir(os.path.join(args.dataDir, tile)):
        if fl.name.endswith('.tif'):
            # cache tile's geometry
            featureTile = osgeo.ogr.Feature(layerDefCache)
            featureTile.SetField('tile', tile)
            rastTile    = gdal.Open(fl.path)
            coordTile   = rastTile.GetGeoTransform()
            xminTile    = coordTile[0]
            yminTile    = coordTile[3]
            xmaxTile    = coordTile[0] + (rastTile.RasterXSize * coordTile[1]) + (rastTile.RasterYSize * coordTile[2])
            ymaxTile    = coordTile[3] + (rastTile.RasterXSize * coordTile[4]) + (rastTile.RasterYSize * coordTile[5])
            wktTile     = 'POLYGON ((%f %f, %f %f, %f %f, %f %f, %f %f))' % (xminTile, yminTile, xmaxTile, yminTile, xmaxTile, ymaxTile, xminTile, ymaxTile, xminTile, yminTile)
            geomTile    = osgeo.ogr.CreateGeometryFromWkt(wktTile)
            prjTile     = osgeo.osr.SpatialReference()
            prjTile.ImportFromWkt(rastTile.GetProjection())
            geomTile.Transform(osgeo.osr.CoordinateTransformation(prjTile, prjCache))
            featureTile.SetGeometry(geomTile)
            layerCache.CreateFeature(featureTile)
            featureTile = None
            break

### Find matching source files
geomSrc.Transform(osgeo.osr.CoordinateTransformation(prjSrc, prjCache))
layerCache.SetSpatialFilter(geomSrc)
tiles = []
for layerTile in layerCache:
    tiles.append(layerTile.GetField('tile'))
logging.info('Matched %d tiles: %s' % (len(tiles), ', '.join(tiles)))
files = []
masks = []
for tile in tiles:
    for fn in os.listdir(os.path.join(args.dataDir, tile)):
        fnp = re.sub('[.][^.]+$', '', fn).split('_')
        if fnp[0] >= args.dateFrom and fnp[0] <= args.dateTo:
            if fnp[1] == args.band:
                files.append({'file': os.path.join(args.dataDir, tile, fn), 'band': fnp[1], 'date': fnp[0], 'tile': tile})
            elif fnp[1] == args.maskBand:
                masks.append({'file': os.path.join(args.dataDir, tile, fn), 'band': fnp[1], 'date': fnp[0], 'tile': tile})
logging.info('Matched %d files' % len(files))

### Cut and reproject
dates = {}
for fl in files:
    if fl['date'] not in dates:
        dates[fl['date']] = {'bands': [], 'masks': []}
    dates[fl['date']]['bands'].append(fl)
for fl in masks:
    if fl['date'] in dates:
        dates[fl['date']]['masks'].append(fl)
inputData = {}
inputMasks = {}
xRes = yRes = None
for date, val in dates.items():
    for key, files in val.items():
        dstFile = os.path.join(args.tmpDir, '%s_%s.tif' % (date, key))
        if key == 'masks':
            inputMasks[date] = dstFile
        else:
            inputData[date] = dstFile

        gdal.Warp(
            dstFile, 
            [x['file'] for x in files], 
            format='GTiff', # output format ("GTiff", etc...) 
            #outputBounds=None, # output bounds as (minX, minY, maxX, maxY) in target SRS
            #outputBoundsSRS=None, # SRS in which output bounds are expressed, in the case they are not expressed in dstSRS
            xRes=xRes, yRes=yRes, # output resolution in target SRS
            #targetAlignedPixels=False, # whether to force output bounds to be multiple of output resolution
            #width=0, height=0, # dimensions of the output raster in pixel
            #srcSRS=None, # source SRS
            dstSRS=prjSrc.ExportToWkt(),  # output SRS
            #srcAlpha=False, # whether to force the last band of the input dataset to be considered as an alpha band
            #dstAlpha=False, # whether to force the creation of an output alpha band
            #warpOptions=None, # https://gdal.org/api/gdalwarp_cpp.html#_CPPv415GDALWarpOptions
            #errorThreshold=None, # error threshold for approximation transformer (in pixels)
            #warpMemoryLimit=None, # size of working buffer in bytes
            creationOptions=['TILED=YES', 'BLOCKXSIZE=512', 'BLOCKYSIZE=512'], # list of creation options
            #outputType=GDT_Unknown, # output type (gdal.GDT_Byte, etc...)
            #workingType=GDT_Unknown, # working type (gdal.GDT_Byte, etc...)
            resampleAlg=args.algorithm, # resampling mode - https://gdal.org/programs/gdalwarp.html#cmdoption-gdalwarp-r
            #srcNodata=None, # source nodata value(s)
            #dstNodata=None, # output nodata value(s)
            multithread=True, # whether to multithread computation and I/O operations
            #tps=False, # whether to use Thin Plate Spline GCP transformer
            #rpc=False, # whether to use RPC transformer
            #geoloc=False, # whether to use GeoLocation array transformer
            #polynomialOrder=None, # order of polynomial GCP interpolation
            #transformerOptions=None, # list of transformer options
            cutlineDSName=fileCut, # cutline dataset name
            cutlineLayer='cutline', # cutline layer name
            #cutlineWhere=None, # cutline WHERE clause
            #cutlineSQL=None, # cutline SQL statement
            #cutlineBlend=None, # cutline blend distance in pixels
            cropToCutline=True, # whether to use cutline extent for output bounds
            #copyMetadata=True, # whether to copy source metadata
            #metadataConflictValue=None, # metadata data conflict value
            #setColorInterpretation=False, # whether to force color interpretation of input bands to output bands
        )
        if xRes is None:
            rastDest  = gdal.Open(dstFile)
            geotrDest = rastDest.GetGeoTransform()
            prjDest   = rastDest.GetProjection()
            dtypeDest = rastDest.GetRasterBand(1).DataType
            X         = rastDest.RasterXSize
            Y         = rastDest.RasterYSize
            xRes      = geotrDest[1]
            yRes      = geotrDest[5]
            rastDest = None


# Prepare outputs
dateMin = datetime.datetime.strptime(min(list(dates)), '%Y-%m-%d').date()
dateMax = datetime.datetime.strptime(max(list(dates)), '%Y-%m-%d').date()
T = (dateMax - dateMin).days + 1

filesOut = []
driver = gdal.GetDriverByName('GTiff')
t = 0
while t < T:
    dateOut = (dateMin + datetime.timedelta(days=t)).isoformat()
    fileOut = os.path.join(args.outputDir, '%s_%s_%s.tif' % (dateOut, args.band, args.outputTileName))
    rastOut = driver.Create(fileOut, X, Y, 1, dtypeDest, args.formatOptions)
    rastOut.SetGeoTransform(geotrDest)
    rastOut.SetProjection(prjDest)
    rastOut.GetRasterBand(1).SetNoDataValue(args.nodataValue)
    rastOut = None
    filesOut.append(fileOut)
    t += args.period

# Compute
P = min(X, args.blockSize) * min(Y, args.blockSize)

y = numpy.empty((P, T), numpy.float32)
w = numpy.empty((P, T), numpy.float32)
c = numpy.empty((P, T), numpy.float32)
d = numpy.empty((P, T), numpy.float32)
z = numpy.empty((P, T), numpy.float32)
m = numpy.empty((P), numpy.bool)

#@jit(nopython=True)
def whittakerC(l, T, y, w, c, d, z, Pmin, Pmax):
    for p in range(Pmin, Pmax):
        if p < y.shape[0]:
            d[p][0] = w[p][0] + l
            c[p][0] = -l / d[p][0]
            z[p][0] = w[p][0] * y[p][0]
            for t in range(1, T - 1):
                d[p][t] = w[p][t] + 2 * l - c[p][t - 1] * c[p][t - 1] * d[p][t - 1]
                c[p][t] = -l / d[p][t]
                z[p][t] = w[p][t] * y[p][t] - c[p][t - 1] * z[p][t - 1]
            d[p][T - 1] = w[p][T - 1] + l - c[p][T - 2] * c[p][T - 2] * d[p][T - 2]
            if d[p][T - 1] > 0:
                z[p][T - 1] = (w[p][T - 1] * y[p][T - 1] - c[p][T - 2] * z[p][T - 2]) / d[p][T - 1]
            else:
                z[p][T - 1] = numpy.nan
            for t in range(T - 2, -1, -1):
                z[p][t] = z[p][t] / d[p][t] - c[p][t] * z[p][t + 1]

def whittakerPool(start):
    end = min(bsx * bsy, start + math.ceil(bsx * bsy / args.nCores))
    whittakerC(args.lmbd, T, y, w, c, d, z, start, end) 

pool = multiprocessing.Pool(args.nCores)
px = 0
while px < X:
    bsx = min(args.blockSize, X - px)
    py = 0
    while py < Y:
        bsy = min(args.blockSize, Y - py)
        p = bsx * bsy
        print('Block %d %d (%d %d) [%d %d]' % (px, py, bsx, bsy, X, Y))

        # initilize what requires initialization
        w.fill(0)
        y.fill(0)

        # read input data
        for date, fn in inputData.items():
            rastMask    = gdal.Open(inputMasks[date])
            bandMask    = rastMask.GetRasterBand(1)

            di         = (datetime.datetime.strptime(date, '%Y-%m-%d').date() - dateMin).days
            rastIn     = gdal.Open(fn)
            bandIn     = rastIn.GetRasterBand(1)
            y[0:p, di] = bandIn.ReadAsArray(px, py, bsx, bsy).reshape((p))
            w[0:p, di] = 1
            w[y[:, di] == bandIn.GetNoDataValue(), di] = 0
            m[0:p]     = bandMask.ReadAsArray(px, py, bsx, bsy).reshape((p)) == bandMask.GetNoDataValue()
            w[m, di]   = 0

            bandMask = None
            rastMask = None
            bandIn   = None
            rastIn   = None

        # apply the whitakker smoother
        #ranges = list(range(0, p, math.ceil(p / args.nCores)))
        #pool.map(whittakerPool, ranges)
        whittakerC(args.lmbd, T, y, w, c, d, z, 0, p)

        # write output
        z[numpy.isnan(z)] = args.nodataValue
        di = 0
        while di < T:
            rastOut = gdal.Open(filesOut[int(di / args.period)], 1)
            bandOut = rastOut.GetRasterBand(1)
            bandOut.WriteArray(z[0:p, di].reshape((bsy, bsx)), px, py)
            bandOut = None
            rastOut = None
            di += args.period

        py += bsy
    px += bsx

#for date, fn in inputData.items():
#    os.unlink(fn)
#for date, fn in inputMasks.items():
#    os.unlink(fn)

