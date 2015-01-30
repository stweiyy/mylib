###library
library(RJDBC)
library(Rwordseg)
library(hash)
###data base connection
port = "30015"
host = "10.128.84.28"
uid = "SYSTEM"
pwd = "manager"
###JDBC connect to the database###################################################
jdbcDriver <- JDBC("com.sap.db.jdbc.Driver", "ngdbc.jar", identifier.quote="`")
ch <- dbConnect(jdbcDriver, paste("jdbc:sap:", host, ":", port, sep=""), uid, pwd)

#step(1): fetch data from database
textinfo <- dbGetQuery(ch, "select CARNAME from WHISLY.BASICINFO")
dbDisconnect(ch)
print(textinfo)

