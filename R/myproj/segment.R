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

print(paste("fetching data: ",Sys.time(),"...."))
#step(1): fetch data from database
textinfo <- dbGetQuery(ch, "select ID,CONTENT from WHISLY.ARTICLES limit 100")
dbDisconnect(ch)
###################################################################################
#step(2):preproccessing ,remove numbers,word segmentation then remove stop words

stopwords<-unlist(read.table("chinesestop.txt",stringsAsFactors=F,quote=""))
wordsegment<-function(content){
    #content=gsub("[0-9０１２３４５６７８９]","",content)
    #content<-gsub("[\'\"]","",content)
	wordslist<-segmentCN(content,nature=TRUE)
	if(!is.null(stopwords)){
		wordslist<-wordslist[!(wordslist %in% stopwords)]
	}
	wordslist<-wordslist[names(wordslist)!='en' & names(wordslist)!='m']
	return(wordslist)
}
print(paste("preproccessing data: ",Sys.time(),"...."))
textinfo$CONTENT<-lapply(textinfo$CONTENT,wordsegment)
textinfo$strvalue<-lapply(textinfo$CONTENT,paste,collapse=",")
dfm<-data.frame(unlist(textinfo$ID),unlist(textinfo$strvalue))
write.table(dfm,"articles_tmp.txt",row.names=FALSE,col.names=FALSE)
print(paste("finished: ",Sys.time(),"...."))
