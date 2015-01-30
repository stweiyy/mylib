#!/usr/bin/python
# -*- coding: utf-8 -*- 
import datetime
import os
import dbapi
import sys
######################################################
#Oracle data types
#Number(p, s)声明一个定点数p(precision)为精度，s(scale)表示小数点右边的数字个数，精度最大值为38，scale的取值范围为-84到127
#Number(p) 声明一个整数,相当于Number(p, 0)
#Number 声明一个浮点数,其精度为38，要注意的是scale的值没有应用，也就是说scale的指不能简单的理解为0，或者其他的数。

###command line arguments##############################
arglen=len(sys.argv)
if arglen<3:
    print "usage :python mkdata.py defn counter"
    print "	defn: the table definition file name"
    print "	counter:the number of records to insert"
    sys.exit()
tablename=sys.argv[1]
counter=sys.argv[2]
print "Begining construct table..."
print "Table name:"+tablename
print "Record count:"+counter

########parse the config file##########################
try:
    fp=open(tablename)
except Exception,e:
    print("open file %s failed!...Quit!" % (tablename))
    sys.exit()
alllines=[x.strip('\n,') for x in fp.readlines()]
fp.close()
fields=[]
for line in alllines:
    line=line.strip()
    line=line.strip(",")
    field={}
    attr=line.split()
    attrname=attr[0]
    attrtype=attr[1]
    if attrtype.find('(')>0:
	if attrtype.find(',')>0:
	    values=attrtype.split('(')
	    attrtype=values[0]
	    field['name']=attrname
	    field['datatype']=attrtype
	    part=values[1]
	    part=part.strip(')')
	    args=part.split(',')
	    field['dataarg']=args[0]
	    field['dataarg1']=args[1]
	else:
	    values=attrtype.split('(')
	    attrtype=values[0]
	    attrarg=values[1].rstrip(')')
	    field['name']=attrname
     	    field['datatype']=attrtype
	    field['dataarg']=attrarg
	
    else:
	field['name']=attrname
	field['datatype']=attrtype
    fields.append(field)

#print fields
#sys.exit()
########sap hana server information###################
serverAddress='10.128.84.28'
serverPort=30015
userName='SYSTEM'
passWord='manager'
#connect to hana database
conn=dbapi.connect(serverAddress,serverPort,userName,passWord)
conn.setautocommit(False)

########make query statement##################################
collist=",".join([x["name"] for x in fields])
numfields=len(fields)
qmark=",".join(['?' for i in range(0,numfields)])
query_stmt="INSERT INTO "+tablename+"("+collist+") VALUES("+qmark+")";

#print query_stmt
cursor=conn.cursor()
########random varchar and random number generator############
import random
import string
import time
def getVarchar(len):
    chars=string.letters+string.digits+' \n\t_-'
    charlen=random.randint(1,len)
    return ''.join([random.choice(chars) for i in range(charlen)])

def getNumber(n):
    chars=string.digits
    str=''.join([random.choice(chars) for i in range(n)])
    return int(str)
def getChar(n):
    chars=string.digits+string.letters
    return ''.join([random.choice(chars) for i in range(n)])
def getDate():
    ts=int(time.time())
    ts=ts-random.randint(0,3600*24*365*4)
    return time.strftime("%Y-%m-%d %H:%M:%S",time.localtime(ts))

def getIdVarchar(n):
    chars=string.digits
    charlen=random.randint(1,n)
    strvalue=''.join([random.choice(chars) for i in range(charlen)])
    return strvalue.lstrip('0')

def getNumber2(m,n):
    chars=string.digits
    intpart=''.join([random.choice(chars) for i in range(m)])
    intpart=intpart.lstrip('0')
    if len(intpart)==m-1:
	intpart='1'+intpart
    fracpart=''.join([random.choice(chars) for i in range(n)])
    return intpart+"."+fracpart

#print getNumber2(3,2)
#sys.exit()

def insOneRecord(fields):
    valuelist=[]
    for j in range(0,len(fields)):
	field=fields[j]
	name=field["name"]
	datatype=field["datatype"]
	if datatype=="VARCHAR2":
            n=int(field["dataarg"])
	    if name.endswith("ID"):
		valuelist.append("'"+getIdVarchar(n)+"'")
	    else:
		valuelist.append("'"+getVarchar(n)+"'")
        elif datatype=="DATE":
            valuelist.append("'"+getDate()+"'")
        elif datatype=="NUMBER":
	    if field.has_key("dataarg1"):
		arg=int(field["dataarg"])
		arg1=int(field["dataarg1"])
		strvalue="'"+getNumber2(arg-arg1,arg1)+"'"
		valuelist.append(strvalue)
	    else:
		n=int(field["dataarg"])
	        strvalue="'"+str(getNumber(n))+"'"
	        valuelist.append(strvalue)
	elif datatype=="CHAR":
	    n=int(field["dataarg"])
	    strvalue="'"+str(getChar(n))+"'"
	    valuelist.append(strvalue)

    valuelist=",".join(valuelist)

    try:
	query_stmt="INSERT INTO "+tablename+"("+collist+") VALUES("+valuelist+")";
	cursor.execute(query_stmt)
    except Exception,ex:
	print ex

for i in range(0,int(counter)):
    insOneRecord(fields)
    if i%9999==0:
	conn.commit();
    
cursor.close()
conn.close()
