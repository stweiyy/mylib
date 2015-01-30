#Sys.setlocale(,"CHS")
library("RJDBC")
library("hash")

port = "30115"
host = "10.128.84.31"
uid = "SYSTEM"
pwd = "manager"
jdbcDriver <- JDBC("com.sap.db.jdbc.Driver", "C:\\Program Files\\sap\\hdbclient\\ngdbc.jar", identifier.quote="`")
ch <- dbConnect(jdbcDriver, paste("jdbc:sap:", host, ":", port, sep=""), uid, pwd)
#step(1): fetch data from database
sentlex <- dbGetQuery(ch, "select WORD,VALUE from WEIYY_TEST.SENTLEX")
#store the sentiment word in a hash table
sentlextbl<-hash(keys=sentlex$WORD,values=sentlex$VALUE)
#store the stop words
stopwords<-dbGetQuery(ch,"select TOKEN FROM WEIYY_TEST.STOPWORDS WHERE TRIM(TOKEN)!=''")
stopwordstbl<-hash(keys=stopwords$TOKEN,values=1)

#fetch the comment a about one book,isbn
isbn<-"9787111303930"

querysql<-"SELECT A.ISBN,C.CID,TOKEN,POS,OFFSET FROM WEIYY_TEST.BOOKINFO A INNER JOIN WEIYY_TEST.TESTCOMMENTS  B ON A.ISBN=B.ISBN INNER JOIN WEIYY_TEST.TA_SEGMENT C ON B.CID=C.CID
WHERE A.ISBN='%s'
ORDER BY C.CID  ASC  ,OFFSET ASC"
querysql<-sprintf(querysql,isbn)

comments<-dbGetQuery(ch,querysql)

cids<- unique(comments$CID)


topicrules<-c("书","作者","源代码","译者","实用","讲解","内容","语言","质量","设计","翻译","推荐","纸张","价格","印刷","代码","分析","包装","发货","速度","纸质","封面","物流","性价比","实用性","插图","装订","品质","排版")

result<-data.frame(stringsAsFactors=T)

for(cid in cids){
  tokenvec<-comments$TOKEN[which(comments$CID==cid)]
  
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
       
        if(target %in% topicrules){
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