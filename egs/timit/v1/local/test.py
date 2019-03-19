#!/usr/bin/env python3

import sys,os

dirt=sys.argv[1]
for file in os.listdir(dirt):
	name,suf=os.path.splitext(file)
	if suf=='.like':
		print(name)
	