#Sys.setlocale(,"CHS")
library("tm")
library("topicmodels")
library("RJDBC")
port = "30115"
host = "10.128.84.31"
uid = "SYSTEM"
pwd = "manager"
jdbcDriver <- JDBC("com.sap.db.jdbc.Driver", "C:\\Program Files\\sap\\hdbclient\\ngdbc.jar", identifier.quote="`")
ch <- dbConnect(jdbcDriver, paste("jdbc:sap:", host, ":", port, sep=""), uid, pwd)
#step(1): fetch data from database
sentlex <- dbGetQuery(ch, "select WORD,VALUE from WEIYY_TEST.SENTLEX")
#store the sentiment word in a hash table
library("hash")
sentlextbl<-hash(keys=sentlex$WORD,values=sentlex$VALUE)
#fetch the comment a about one book,isbn
isbn<-"9787111303930"
sql<-"SELECT A.ISBN,C.CID,TOKEN,POS,OFFSET FROM WEIYY_TEST.BOOKINFO A INNER JOIN WEIYY_TEST.TESTCOMMENTS  B ON A.ISBN=B.ISBN INNER JOIN WEIYY_TEST.TA_SEGMENT C ON B.CID=C.CID

ORDER BY C.CID  ASC  ,OFFSET ASC"
sql<-gsub("-",isbn,sql)

comments<-dbGetQuery(ch,sql)
cids<- unique(comments$CID)
#the search step
#maxsearchlength<-3
posrules<-c("n","ng","nr","ns","nt","nz","v","vd","vg","vi","vn","vq")
result<-data.frame(stringsAsFactors=T)

sourcevec<-list()
i<-1
for(cid in cids){
  sourcevec[[i]]<-comments$TOKEN[which(comments$CID==cid)]
  i<-i+1
}

corpus<-Corpus(VectorSource(sourcevec))
dtm <- DocumentTermMatrix(corpus, control = list(wordLengths = c(1, Inf)))


#clear the hash table
clear(sentlextbl)