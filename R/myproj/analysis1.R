###library
library(RJDBC)
library(Rwordseg)
library(hash)
###data base connection
port = "30015"
host = "10.128.84.28"
uid = "SYSTEM"
pwd = "manager"

##change the option##############
options(stringsAsFactors = FALSE)

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
record<-merge(carswords,salesinfo,by.x="CARID",by.y="CARID")

wordscore<-do.call(rbind.data.frame,apply(record,1,function(obj){
	salecount<-as.integer(obj[5])
	wordslist<-obj[3]
	wordsfreq<-table(wordslist)
	tweight<-sum(wordsfreq)
	r1<-do.call(rbind,lapply(1:length(wordsfreq),function(x){
				return(c(names(wordsfreq[x]),salecount*wordsfreq[x]/tweight))
			}))
	colnames(r1)<-c("words","score")
	return(r1);
}))
wordscore$score<-as.numeric(wordscore$score)
result<-aggregate(score~words, sum, data=wordscore)
r3<-result[order(result$score,decreasing = TRUE),]
write.table(r3,"wordscore.txt",sep="\t",row.names=FALSE,col.names=FALSE)
