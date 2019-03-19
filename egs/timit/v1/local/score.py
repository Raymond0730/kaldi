#!/usr/bin/env python3


import sys,os

dirt=sys.argv[1]
score=open(sys.argv[2],'w')
uttDict={}
total=0
err=0
for file in os.listdir(dirt):
	if(file=='ubm'):
		filepath=os.path.join(dirt,file)
		for line in open(filepath):
			line=line.rstrip('\r\t\n ')
			utt,ubmLike=line.split(' ')
			ubmLike=float(ubmLike)
			if utt not in uttDict:
				uttDict[utt]=[] # 0 stores ubm likelihood, 1 stores highest speaker model likelihood, 2 stores highest likelihood speaker, 3 stores log
								# likelihood ratio between the highest speaker model and ubm
			uttDict[utt].append(ubmLike)

for file in os.listdir(dirt):
	name,suf=os.path.splitext(file)
	if suf=='.like':
		filepath=os.path.join(dirt,file)
		for line in open(filepath):
			line = line.rstrip('\r\t\n ')
			utt,like=line.split(' ')
			like=float(like)
			if len(uttDict[utt])==1:
				uttDict[utt].append(like)
			if len(uttDict[utt])==2:
				uttDict[utt].append(name)
			if like>uttDict[utt][1]:
				uttDict[utt][1]=like
				uttDict[utt][2]=name
for utt in uttDict:
	ratio=uttDict[utt][1]-uttDict[utt][0]
	line=utt+' '+uttDict[utt][2]+' '+str(ratio)+'\n'
	if utt[0:5]!= uttDict[utt][2]:
		err=err+1
	score.write(line)
total=len(uttDict)
score.write(str(err/total))
score.close()


	
