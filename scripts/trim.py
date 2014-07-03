#!/usr/bin/env python
import sys


if len(sys.argv) > 1:
    readLen = int(sys.argv[1])
else:
    exit()

fq = sys.stdin.read()
fq = fq.split('\n')

i = 0

while i + 4 < len(fq):
    if len(fq[i + 1]) >= readLen:
        print(fq[i])
        print(fq[i + 1][:readLen])
        print(fq[i + 2])
        print(fq[i + 3][:readLen])
    i = i + 4
