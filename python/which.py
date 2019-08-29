#!python

import argparse
import datetime
import gdal
import numpy
import os
import re


parser = argparse.ArgumentParser(description='Computes a raster file denoting which input file contained a maximum value for a given pixel. By default it is a numeric index of the input file but it can be also a value extracted from the file name.')
parser.add_argument('--verbose', action='store_true')
parser.add_argument('--blockSize', type=int, default=3072)
parser.add_argument('--gdalCacheSize', type=int, default=2147483648)
parser.add_argument('--formatOptions', nargs='*', default=['COMPRESS=DEFLATE', 'TILED=YES', 'BLOCKXSIZE=512', 'BLOCKYSIZE=512'], help='output format options')
parser.add_argument('--valueRegex', help='a regular expression matching the input file name part to be used as a value')
parser.add_argument('--valueTransform', choices=['asInt', 'date2doy'], default='asInt', help='how to transform a value extracted with the --valueRegex')
parser.add_argument('outFileName')
parser.add_argument('inputFile', nargs='+')
args = parser.parse_args()

if args.gdalCacheSize is not None:
    gdal.SetCacheMax(args.gdalCacheSize)

valuesMap = None
outMax = len(args.inputFile)
if args.valueRegex is not None:
    valuesMap = [re.search(args.valueRegex, i).group(0) for i in args.inputFile]
    if args.valueTransform == 'asInt':
        valuesMap = [int(i) for i in valuesMap]
    elif args.valueTransform == 'date2doy':
        valuesMap = [int(datetime.datetime.strptime(i, '%Y-%m-%d').strftime('%-j')) for i in valuesMap]
    outMax = max(valuesMap)

src = [] # we must keep file objects because without them band objects get corrupted
srcBands = []
for i in args.inputFile:
    tmp = gdal.Open(i)
    src.append(tmp)
    srcBands.append(tmp.GetRasterBand(1))
nodataSrc = srcBands[0].GetNoDataValue()

dataType = gdal.GDT_Byte if outMax < 255 else gdal.GDT_UInt16
nodataDst = 255 if outMax < 255 else 65535
if valuesMap is not None:
    valuesMap = valuesMap + [0] * (nodataDst - len(valuesMap)) + [nodataDst]
    valuesMap = numpy.array(valuesMap)

driver = gdal.GetDriverByName('GTiff')
dst = driver.Create(args.outFileName, src[0].RasterXSize, src[0].RasterYSize, 1, dataType, args.formatOptions)
dst.SetGeoTransform(src[0].GetGeoTransform())
dst.SetProjection(src[0].GetProjection())
dstBand = dst.GetRasterBand(1)
dstBand.SetNoDataValue(nodataDst)

t = datetime.datetime.now()
px = 0
while px < src[0].RasterXSize:
    bsx = min(args.blockSize, src[0].RasterXSize - px)
    py = 0
    while py < src[0].RasterYSize:
        if args.verbose:
            print('%d %d (%s)' % (px, py, datetime.datetime.now() - t))
        t = datetime.datetime.now()
        bsy = min(args.blockSize, src[0].RasterYSize - py)

        dataSrc = []
        for i in srcBands:
            dataSrc.append(i.ReadAsArray(px, py, bsx, bsy))
        dataSrc = numpy.stack(dataSrc)
        nodataMask = dataSrc == nodataSrc
        dataSrc[nodataMask] = numpy.iinfo(dataSrc.dtype).min
        dataMax = dataSrc.max(0)
        dataDst = numpy.zeros(dataSrc.shape, numpy.uint8)
        for i in xrange(len(srcBands)):
            dataDst[i, :, :] = numpy.where(dataSrc[i, :, :] == dataMax, i, nodataDst)
        del dataSrc, dataMax
        dataDst[nodataMask] = nodataDst
        del nodataMask
        dataDst = dataDst.min(0)
        if valuesMap is not None:
            dataDst = valuesMap.take(dataDst)
        dstBand.WriteArray(dataDst, px, py)
        del dataDst
  
        py += bsy
    px += bsx

