library(hash)
library(RJDBC)


port<-"30115"
host<-"10.128.84.31"

uid<-"SYSTEM"
pwd<-"manager"

jdbcDriver <- JDBC("com.sap.db.jdbc.Driver", "/home/R/ngdbc.jar", identifier.quote="`")
ch <- dbConnect(jdbcDriver, paste("jdbc:sap:", host, ":", port, sep=""), uid, pwd)
#step(1): fetch data from database
sentlex <- dbGetQuery(ch, "select \"word\",\"value\" from \"BCAS\".\"BCAS.data::sentlex\"")
#store the sentiment word in a hash table

sentlextbl<-hash(keys=sentlex$word,values=sentlex$value)


processone<-function(isbn){
  
  
  querysql<-
    
    "select A.\"isbn\",B.\"id\",\"token\",\"pos\",\"offset\" from \"BCAS.data::informationSource\" A 
  inner join \"BCAS.data::commentSource\" B ON A.\"id\"=B.\"idOfInfo\" 
  inner join \"BCAS.data::taSegment\" C on B.\"id\"=C.\"idComment\"
  where A.\"isbn\"='%s'
  ORDER BY C.\"idComment\"  ASC  ,\"offset\" ASC
  "
  
  
  querysql<-sprintf(querysql,isbn)
  
  comments<-dbGetQuery(ch,querysql)
  
  cids<- unique(comments$id)
  topicrules<-c("书","作者","源代码","译者","实用","讲解","内容","语言","质量","设计","翻译","推荐","纸张","价格","印刷","代码","分析","包装","发货","速度","纸质","封面","物流","性价比","实用性","插图","装订","品质","排版")
  
  
  result<-data.frame(stringsAsFactors=T)
  
  for(cid in cids){
    tokenvec<-comments$token[which(comments$id==cid)]
    
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
            #unify the topics
            if(target=="价钱"){target<-"价格"}
            if(target=="实用"){target<-"实用性"}
            if(target=="代码"){target<-"源代码"}
            
            
            #for some topic ,reverse the sentiment
            if(target=="价格"){
              tokensentvalue<-(-tokensentvalue)
            }
            senttype<-"positive"
            if(tokensentvalue==-1){senttype="negative"}
            result<-rbind(result,data.frame(target,tokentag,senttype,tokensentvalue,stringsAsFactors  
                                            =T))
            
            #print(recordpair)
            break
          }
        }
      }
    }
  }
  tempout<-aggregate(tokensentvalue~target+senttype,sum,data=result)
  isbn<-rep(isbn,nrow(tempout))
  tempout<-cbind(isbn,tempout)
  
  total<-nrow(tempout)
  for(i in 1:total){
    insertstat<-sprintf("insert into WEIYY_TEST.SENTRESULT VALUES('%s','%s','%s','%d')",tempout$isbn[i],tempout$target[i],tempout$senttype[i],tempout$tokensentvalue[i])
    dbSendUpdate(ch,insertstat);
  }
  
}


fetchisbnquery<-"select \"isbn\" from \"BCAS\".\"BCAS.data::informationSource\" where \"isbn\" not in 
(select distinct(\"isbn\") from \"WEIYY_TEST\".\"SENTRESULT\")"

allisbn<-dbGetQuery(ch,fetchisbnquery)

for(i in 1:length(allisbn$isbn)){
  isbn<-allisbn$isbn[i]
  processone(isbn=isbn)
}

#clear the hash table
clear(sentlextbl)
dbDisconnect(ch)
