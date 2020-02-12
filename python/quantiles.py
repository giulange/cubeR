#!python

import argparse
import datetime
import gdal
import numpy
import os
import re


parser = argparse.ArgumentParser()
parser.add_argument('--verbose', action='store_true')
parser.add_argument('--blockSize', type=int, default=512)
parser.add_argument('--gdalCacheSize', type=int, default=2147483648)
parser.add_argument('--mode', default='precise', choices=['precise', 'fast'])
parser.add_argument('--q', nargs='*', default=[0.5], type=float)
parser.add_argument('--formatOptions', nargs='*', default=['COMPRESS=DEFLATE', 'TILED=YES', 'BLOCKXSIZE=512', 'BLOCKYSIZE=512'], help='output format options')
parser.add_argument('outFileNameFormat')
parser.add_argument('inputFile')
args = parser.parse_args()

if args.gdalCacheSize is not None:
    gdal.SetCacheMax(args.gdalCacheSize)

##
#src = [] # we must keep file objects because without them band objects get corrupted
#srcBands = []
#with open(args.inputFile) as fi:
#    for i in fi:
#        tmp = gdal.Open(i.strip())
#        src.append(tmp)
#        srcBands.append(tmp.GetRasterBand(1))
with open(args.inputFile) as fi:
    srcFiles = [i.strip() for i in fi.readlines()]
##
nodata = srcBands[0].GetNoDataValue()

driver = gdal.GetDriverByName('GTiff')
dst = []
dstBands = []
for i in args.q:
    i = args.outFileNameFormat % (i * 100)
    tmp = driver.Create(i, src[0].RasterXSize, src[0].RasterYSize, 1, srcBands[0].DataType, args.formatOptions)
    tmp.SetGeoTransform(src[0].GetGeoTransform())
    tmp.SetProjection(src[0].GetProjection())
    dst.append(tmp)
    tmpBand = tmp.GetRasterBand(1)
    tmpBand.SetNoDataValue(nodata)
    dstBands.append(tmpBand)

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

        # read source data into array [pixel, time]
        dataSrc = []
        #for i in srcBands:
        #    dataSrc.append(i.ReadAsArray(px, py, bsx, bsy))
        for i in srcFiles:
            tmp = gdal.Open(i)
            dataSrc.append(tmp.GetRasterBand(1).ReadAsArray(px, py, bsx, bsy))
        dataSrc = numpy.stack(dataSrc, -1).reshape((bsy * bsx, len(srcBands)))
        # reorganize in a way nodata values are always last on the time axis
        nodataTmp = numpy.iinfo(dataSrc.dtype).max
        dataSrc[dataSrc == nodata] = nodataTmp
        dataSrc = numpy.sort(dataSrc, -1)

        dataDst = numpy.zeros((len(args.q), bsy * bsx), dataSrc.dtype)
        dataDst.fill(nodata)

        # for each number of present data values (n) process a homogenous array of size [numberOfPixelsWithSuchN, n]
        # as number of possible n values is by few orders of magnitude smaller than number of pixels it provides a significant speedup
        nNodata = len(srcBands) - numpy.sum(dataSrc == nodataTmp, -1)
        for n in set(numpy.unique(nNodata)) - set((0, )):
            mask = nNodata == n
            if args.mode == 'fast':
                idx = (numpy.array(args.q) * (n - 1)).round().astype('int').tolist()
                tmp = dataSrc[mask, :]
                dataDst[mask, :] = tmp[:, idx]
            else:
                dataDst[:, mask] = numpy.quantile(dataSrc[mask, 0:n], args.q, -1)

        # go back to the [bsy, bsx, quantile] format and write output
        dataDst = dataDst.reshape((len(args.q), bsy, bsx))

        for i in range(len(args.q)):
            dstBands[i].WriteArray(dataDst[i, :, :], px, py)

        py += bsy
    px += bsx

