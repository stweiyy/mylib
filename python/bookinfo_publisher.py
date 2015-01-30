# -*- coding: utf-8 -*-
import os
import re
import dbapi #import the  database connect api

#note: in order to output chinese information ,it may need to use encode("utf-8")

#connect arguments
serverAdress='10.128.84.31'
serverPort=30115
userName='SYSTEM'
passWord='manager'

#store the publisher information
publist={}
counter=1 #publisher count ,for the use of new id of the publisher

#connect to hana database
conn=dbapi.connect(serverAdress,serverPort,userName,passWord)
getAllPubId="select PUBID,PUBNAME from GW.PUBLISHER"

query="select * FROM GW.DOU_INFO"
insert_to_bookinfo="insert into GW.BOOKINFO(ISBN,BOOKNAME,WRITERS,TRANSLATORS,PUBID) VALUES(?,?,?,?,?)"
insert_to_publisher="insert into GW.PUBLISHER(PUBID,PUBNAME) VALUES(?,?)"

cursor=conn.cursor()
allPub=cursor.execute(getAllPubId)
allPub=cursor.fetchall()
for row in allPub:
	pubId=row[0]
	pubName=row[1]
	publist[pubName]=pubId

#the next publisher id for using
counter=len(publist)+1

	


ret=cursor.execute(query)
ret=cursor.fetchall()



loger=open("insertlog_DOU.txt","w")


for row in ret:
	'''isbn=row[4].strip()
	
	name=row[1]
	writer=row[2]
	translator=row[3]
	phouse=row[5].strip()
	#ptime=row[6]'''
	isbn=row[5].strip()
	
	name=row[1]
	writer=row[3]
	translator=row[4]
	phouse=row[6].strip()
	
	
	pubId=0
	
	if phouse in publist.keys():
		pubId=publist[phouse]
	else:
		publist[phouse]=counter
		counter=counter+1
		pubId=publist[phouse]
		try:
			cursor.execute(insert_to_publisher,(pubId,phouse))
			loger.write("insert:"+"\t"+str(pubId)+"\t"+phouse+"\n")
		except Exception,ex:
			#pass
			print ex
		
	try:
		cursor.execute(insert_to_bookinfo,(isbn,name,writer,translator,pubId))
		loger.write("insert:"+"\t"+isbn+"\t"+name+"\n")
	except Exception,ex:
		#pass
		print ex
		print "isbn:"+isbn+"\n"
	
	
loger.close()
conn.close()
os.system('pause')