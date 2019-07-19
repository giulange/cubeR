#!python

import argparse
import datetime
import gdal
import numpy
import os
import re


parser = argparse.ArgumentParser()
parser.add_argument('--verbose', action='store_true')
parser.add_argument('--binary', action='store_true', help='should any value other than 0 be counted as 1?')
parser.add_argument('--includeZero', action='store_true', help='should 0 be counted as 1? (with --binary counts valid values for a pixel excluding nodata)')
parser.add_argument('--blockSize', type=int, default=512)
parser.add_argument('--gdalCacheSize', type=int, default=2147483648)
parser.add_argument('--formatOptions', nargs='*', default=['COMPRESS=DEFLATE', 'TILED=YES', 'BLOCKXSIZE=512', 'BLOCKYSIZE=512'], help='output format options')
parser.add_argument('outputFileName')
parser.add_argument('inputFile')
args = parser.parse_args()

if args.gdalCacheSize is not None:
    gdal.SetCacheMax(args.gdalCacheSize)

src = [] # we must keep file objects because without them band objects get corrupted
srcBands = []
with open(args.inputFile) as fi:
    for i in fi:
        tmp = gdal.Open(i.strip())
        src.append(tmp)
        srcBands.append(tmp.GetRasterBand(1))
nodata = srcBands[0].GetNoDataValue()

driver = gdal.GetDriverByName('GTiff')
dst = driver.Create(args.outputFileName, src[0].RasterXSize, src[0].RasterYSize, 1, gdal.GDT_UInt16, args.formatOptions)
dst.SetGeoTransform(src[0].GetGeoTransform())
dst.SetProjection(src[0].GetProjection())
dstBand = dst.GetRasterBand(1)

t = datetime.datetime.now()
px = 0
while px < src[0].RasterXSize:
    bsx = min(args.blockSize, src[0].RasterXSize - px)
    py = 0
    while py < src[0].RasterYSize:
        bsy = min(args.blockSize, src[0].RasterYSize - py)
        if args.verbose:
            print('%d %d %d %d (%s)' % (px, py, bsx, bsy, datetime.datetime.now() - t))
        t = datetime.datetime.now()

        # read source data into array [y, x, time]
        dataSrc = []
        for i in srcBands:
            dataSrc.append(i.ReadAsArray(px, py, bsx, bsy))
        dataSrc = numpy.stack(dataSrc, -1)

        if args.includeZero and nodata != 0:
            dataSrc[dataSrc == 0] = 1
        dataSrc[dataSrc == nodata] = 0
        if args.binary:
            dataSrc = dataSrc != 0

        # sum along [y, x] and write back
        dataSrc = numpy.sum(dataSrc, -1)
        dstBand.WriteArray(dataSrc, px, py)

        py += bsy
    px += bsx

