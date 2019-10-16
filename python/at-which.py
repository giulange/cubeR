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
parser.add_argument('--gdalCacheSize', type=int, default=2147483648)
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
    tmpBands = []
    for j in range(tmp.RasterCount):
        tmpBands.append(tmp.GetRasterBand(j + 1))
    srcBands.append(tmpBands)
nBands = len(srcBands[0])
nodata = srcBands[0][0].GetNoDataValue()

which = gdal.Open(args.whichFile)
whichBand = which.GetRasterBand(1)
nodataWhich = whichBand.GetNoDataValue()

for i in src:
    if i.RasterXSize != which.RasterXSize or i.RasterYSize != which.RasterYSize:
        raise Exception('Source files dimentions do not match')

driver = gdal.GetDriverByName('GTiff')
dst = driver.Create(args.outFile, src[0].RasterXSize, src[0].RasterYSize, nBands, srcBands[0][0].DataType, args.formatOptions)
dst.SetGeoTransform(src[0].GetGeoTransform())
dst.SetProjection(src[0].GetProjection())
dstBands = []
for i in range(nBands):
    tmpBand = dst.GetRasterBand(i + 1)
    if nodata is not None:
        tmpBand.SetNoDataValue(nodata)
    dstBands.append(tmpBand)

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

        for band in range(nBands):
            dataDst = numpy.zeros((bsy, bsx))

            for i in range(len(srcBands)):
                dataSrc = srcBands[i][band].ReadAsArray(px, py, bsx, bsy)
                dataDst = dataDst + dataSrc * (dataWhich == i)
       
            if nodata is not None:
                dataDst[dataWhich == nodataWhich] = nodata
            dstBands[band].WriteArray(dataDst, px, py)

        py += bsy
    px += bsx

