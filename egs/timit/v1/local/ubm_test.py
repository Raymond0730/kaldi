#!/usr/bin/env python3


import sys,os

dirt=sys.argv[1]
ubm_test=open(sys.argv[2],'w')
utt_update={}
utt_like={}
for x in range (0,20):
	file=str(x)+'.like'
	filepath=os.path.join(dirt,file)
	for line in open(filepath):
		line = line.rstrip('\r\t\n ')
		utt,like=line.split(' ')
		like=float(like)
		if utt not in utt_like:
			utt_like[utt]=like
		if utt not in utt_update:
			utt_update[utt]=''
		if like>utt_like[utt]:
			utt_update[utt]+='+ '
		if like<utt_like[utt]:
			utt_update[utt]+='- '
		utt_like[utt]=like
for utt in utt_update:
	line=utt_update[utt]+'\n'
	ubm_test.write(line)
ubm_test.close()

	
