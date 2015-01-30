# -*- coding: utf-8 -*-
import os
import re
import dbapi #import the  database connect api

#note: in order to output chinese information ,it may need to use encode("utf-8")

#connect arguments
serverAdress='10.128.74.125'
serverPort=30015
userName='SYSTEM'
passWord='manager'

#connect to hana database
conn=dbapi.connect(serverAdress,serverPort,userName,passWord)
print conn.isconnected()

conn.close()
os.system('pause')