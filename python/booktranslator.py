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

#connect to hana database
conn=dbapi.connect(serverAdress,serverPort,userName,passWord)
#query="select * FROM GW.DOU_INFO"
query="SELECT ISBN,TRANSLATORS FROM GW.BOOKINFO WHERE ISBN NOT IN (SELECT DISTINCT ISBN FROM GW.BOOKTRANSLATOR)"

insert_to_booktranslator="insert into GW.BOOKTRANSLATOR VALUES(?,?)"


cursor=conn.cursor()
ret=cursor.execute(query)
ret=cursor.fetchall()

exceptlog=open("exceptlog-bookinfo.txt","w")
insertlog=open("insertlog-bookinfo.txt","w")


for row in ret:
	
	#isbn=row[5].strip()
	isbn=row[0].strip()
	translators=row[1].strip()
	translators=re.sub(ur"\s+译$","",translators)
	translators=re.sub(ur"[，,]*\s*等$","",translators)
	translators=re.sub(ur"等","",translators)
	translators=re.sub(ur"\([\u4e00-\u9fa5]+\)","",translators)
	translators=re.sub(ur"作者","",translators)
	translators=re.sub(ur"/",",",translators)
	translators=re.sub(ur";",",",translators)
	translators=re.sub(ur"译者","",translators)
	translators=re.sub(ur"[\(]","",translators)
	translators=re.sub(ur"[\)]","",translators)
	translators=re.sub(ur"\s*译","",translators)
	if(translators.find(u"编")>=0):
		exceptlog.write(isbn+'\t')
		exceptlog.write(translators.encode('utf-8'))
		exceptlog.write('\n')
		continue
	translators=re.sub(ur"，",",",translators)
	translators=translators.split(",")
	
	for translator in translators:
		translator=translator.strip()
		try:
			if  translator.strip():
				#print isbn+"\t"+translator
				cursor.execute(insert_to_booktranslator,(isbn,translator))
		except Exception,ex:
			print ex
			insertlog.write((isbn+"\t"+translator+"\n").encode('utf-8'))
			#print "isbn:"+isbn+"\t"+translator


#close connection
conn.close()
exceptlog.close()
insertlog.close()
os.system('pause')