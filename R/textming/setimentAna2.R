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

querysql<-"SELECT CID,CONTENT FROM WEIYY_TEST.TESTCOMMENTS WHERE ISBN='%s'";
querysql<-sprintf(querysql,isbn)

comments<-dbGetQuery(ch,querysql)


#the search step
#maxsearchlength<-3
posrules<-c("n","ng","nr","ns","nt","nz","v","vd","vg","vi","vn","vq")

result<-data.frame(stringsAsFactors=T)

for(cid in 1:length(comments$CONTENT)){
  
  content<-comments$CONTENT[cid]
  content<-gsub("[0-9０１２３４５６７８９]","",content)
  if(nchar(content)<3){next}
  tokenvec<-segmentCN(content,nature=TRUE)
  posvec<-names(tokenvec)
  rindex<-1
  removelist<-c()
  for(rindex in 1:length(tokenvec)){
    if(has.key(tokenvec[rindex],stopwordstbl)){
      removelist<-c(removelist,rindex)
    }
  }
  if(length(removelist)>=1){
    tokenvec<-tokenvec[-removelist]
    posvec<-posvec[-removelist]    
  }
  if(length(tokenvec)<1){next}
 
  tokenindex<-1
 # print(tokenvec)
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