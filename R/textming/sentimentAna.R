#Sys.setlocale(,"CHS")
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
WHERE A.ISBN='-'
ORDER BY C.CID  ASC  ,OFFSET ASC"
sql<-gsub("-",isbn,sql)

comments<-dbGetQuery(ch,sql)
cids<- unique(comments$CID)
#the search step
#maxsearchlength<-3
posrules<-c("n","ng","nr","ns","nt","nz","v","vd","vg","vi","vn","vq")
result<-data.frame(stringsAsFactors=T)

for(cid in cids){
  tokenvec<-comments$TOKEN[which(comments$CID==cid)]
  posvec<-comments$POS[which(comments$CID==cid)]
  tokenindex<-1
  for(tokenindex in 1:length(tokenvec)){
    tokentag<-tokenvec[tokenindex]
    if(has.key(tokentag,sentlextbl)){
      tokensentvalue<-sentlextbl[[tokentag]]
      searchseq<-c(tokenindex-1,tokenindex-2,tokenindex+1,tokenindex+2)
      removeindex<-which(searchseq<1|searchseq>length(tokenvec))
      searchseq<-searchseq[-removeindex]
      for(sseq in searchseq){
        target<-tokenvec[sseq]
        targetpos<-posvec[sseq]
        if((targetpos %in% posrules)&&(nchar(target)>1)){
          #for some topic ,reverse the sentiment
          if((target) %in% c("价格","价钱")){
            tokensentvalue<-(-tokensentvalue)
          }
          senttype<-"positive"
          if(tokensentvalue==-1){senttype="negative"}
          result<-rbind(result,data.frame(target,tokentag,senttype,tokensentvalue,stringsAsFactors  
=T))
          break
        }
      }
    }
  }
}

tempout<-aggregate(tokensentvalue~target+senttype,sum,data=result)

#clear the hash table
clear(sentlextbl)