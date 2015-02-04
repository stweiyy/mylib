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
#step(1): fetch sales data from database
salesinfo <- dbGetQuery(ch, "select CARID,CARNAME,NUM from WHISLY.TMPSALE1")
#print(salesinfo)
useddoc<-dbGetQuery(ch,"select ID,CARID FROM WHISLY.ARTICLES WHERE CARID IN (SELECT CARID FROM WHISLY.TMPSALE1)")
dbDisconnect(ch)
#step(2): get text information
carswords<-read.table("tfidf_kw.txt",header=FALSE,col.names=c("articleID","WORDS"),stringsAsFactors=FALSE)
#carswords$wordslist<-strsplit(carswords$WORDS,",")
usedwords<-carswords[carswords$articleID %in% useddoc$ID,]
rm(carswords);
mydf<-merge(usedwords,useddoc,by.x="articleID",by.y="ID")
carswords<-aggregate(WORDS~CARID,data=mydf,FUN=paste, collapse=",")  
carswords$wordsvec<-strsplit(carswords$WORDS,",")
#print(head(usedwords))
result<-apply(carswords,1,function(obj){
	carsno<-obj[1]
	carswords<-obj[3]
	wordsfreq<-sort(table(carswords),decreasing = TRUE)
	wordslist<-wordsfreq[1:100]
	wordsvec<-sapply(1:length(wordslist),function(x){
		paste(names(wordslist[x]),wordslist[x],sep=":")
	})
	wordsstr<-paste(wordsvec,collapse=",")
	return(data.frame(carsno=carsno,wordsstr=wordsstr,stringsAsFactors=FALSE))
})
resultdf<-do.call(rbind.data.frame,result)
write.table(resultdf,"carskeywords.txt",sep="\t",row.names=FALSE,col.names=FALSE)
