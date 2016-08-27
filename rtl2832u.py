#!/usr/bin/env python
# Copyright (C) 2012 Antti Palosaari <crope@iki.fi>
# Script generates code from the RTL2832U USB-sniff.
# Usage:

import sys
import re

fread = file(sys.argv[1], 'r' )

def get_hex_string(ele, start, length):
    string = '"'
    for i in range(length):
        string = string + '\\x' + ele[start + i]
    string = string + '"'
    return string

for line in fread:
    line = line.strip();
    ele = re.split(' ', line)

    # print '// ' + line

    # rtl2832u - USB interface
    if (len(ele) > 17 and ele[15] == '>>>' and (
            (ele[11] == '10' and ele[12] == '01') or
            (ele[11] == '10' and ele[12] == '02') or
            (ele[11] == '11' and ele[12] == '02'))):
        length = int(ele[13], 16)
        reg = '0x' + ele[10] + ele[9]
        print 'ret = rtl28xx_wr_regs(d, ' + reg + ', ' + \
            get_hex_string(ele, 17, length) + ', ' + str(length) + '); // generated'

    # rtl2832 - demod
    if (len(ele) > 17  and ele[9] == '20' and ele[15] == '>>>'):
        length = int(ele[13], 16)
        bank = ele[11][1]
        print 'ret = rtl2832_wr_regs(priv, 0x' + ele[10] + ', ' + bank + ', ' + \
            get_hex_string(ele, 17, length) + ', ' + str(length) + '); // generated'

     # e4000
    if (len(ele) > 17  and ele[9] == 'c8' and ele[13] != '01' and ele[15] == '>>>'):
        length = int(ele[13], 16) - 1
        print 'ret = e4000_wr_regs(priv, 0x' + ele[17] + ', ' + \
            get_hex_string(ele, 18, length) + ', ' + str(length) + '); // generated'

     # fc2580
    if (len(ele) > 17  and ele[9] == 'ac' and ele[13] != '01' and ele[15] == '>>>'):
        length = int(ele[13], 16) - 1
        print 'ret = fc2580_wr_regs(priv, 0x' + ele[17] + ', ' + \
            get_hex_string(ele, 18, length) + ', ' + str(length) + '); // generated'

     # fc0013
    if (len(ele) > 17  and ele[9] == 'c6' and ele[13] != '01' and ele[15] == '>>>'):
        print 'ret = fc0013_writereg(priv, 0x' + ele[17] + ', 0x' + \
            ele[18] + '); // generated'

     # tua9001
    if (len(ele) > 17  and ele[9] == 'c0' and ele[15] == '>>>'):
        print 'ret = tua9001_wr_reg(priv, 0x' + ele[17] + ', 0x' + \
            ele[18] + ele[19] + '); // generated'

    # r820t
    if (len(ele) > 17  and ele[9] == '34' and ele[13] != '01' and ele[15] == '>>>'):
        length = int(ele[13], 16) - 1
        print 'ret = r820t_write(priv, 0x' + ele[17] + ', ' + \
            get_hex_string(ele, 18, length) + ', ' + str(length) + '); // generated'

fread.close()

