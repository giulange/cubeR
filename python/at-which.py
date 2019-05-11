#!python

import argparse
import datetime
import gdal
import numpy
import os
import re


parser = argparse.ArgumentParser()
parser.add_argument('--verbose', action='store_true')
parser.add_argument('--blockSize', type=int, default=4096)
parser.add_argument('--gdalCacheSize', type=int)
parser.add_argument('--formatOptions', nargs='*', default=['COMPRESS=DEFLATE', 'TILED=YES', 'BLOCKXSIZE=512', 'BLOCKYSIZE=512'], help='output format options')
parser.add_argument('outFile')
parser.add_argument('whichFile')
parser.add_argument('inputFile', nargs='+')
args = parser.parse_args()

if args.gdalCacheSize is not None:
    gdal.SetCacheMax(args.gdalCacheSize)

src = [] # we must keep file objects because without them band objects get corrupted
srcBands = []
for i in args.inputFile:
    tmp = gdal.Open(i)
    src.append(tmp)
    srcBands.append(tmp.GetRasterBand(1))
nodata = srcBands[0].GetNoDataValue()

which = gdal.Open(args.whichFile)
whichBand = which.GetRasterBand(1)
nodataWhich = whichBand.GetNoDataValue()

driver = gdal.GetDriverByName('GTiff')
dst = driver.Create(args.outFile, src[0].RasterXSize, src[0].RasterYSize, 1, srcBands[0].DataType, args.formatOptions)
dst.SetGeoTransform(src[0].GetGeoTransform())
dst.SetProjection(src[0].GetProjection())
dstBand = dst.GetRasterBand(1)
dstBand.SetNoDataValue(nodata)

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

        dataWhich = whichBand.ReadAsArray(px, py, bsx, bsy)
        # dataWhich has shape (bsy, bsx)!
        dataDst = numpy.zeros((bsy, bsx))

        for i in xrange(len(srcBands)):
            dataSrc = srcBands[i].ReadAsArray(px, py, bsx, bsy)
            dataDst = dataDst + dataSrc * (dataWhich == i)
       
        dataDst[dataWhich == nodataWhich] = nodata
        dstBand.WriteArray(dataDst, px, py)

        py += bsy
    px += bsx

