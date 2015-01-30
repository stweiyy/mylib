#Sys.setlocale(,"CHS")
library("RJDBC")
port = "30115"
host = "10.128.84.31"
uid = "SYSTEM"
pwd = "manager"
jdbcDriver <- JDBC("com.sap.db.jdbc.Driver", "C:\\Program Files\\sap\\hdbclient\\ngdbc.jar", identifier.quote="`")
ch <- dbConnect(jdbcDriver, paste("jdbc:sap:", host, ":", port, sep=""), uid, pwd)
#step(1): fetch data from database
textinfo <- dbGetQuery(ch, "select CID,CONTENT from WEIYY_TEST.TESTCOMMENTS")

stopwords<-dbGetQuery(ch,"select TOKEN from WEIYY_TEST.STOPWORDS")
stopwords<-stopwords$TOKEN

#step(2):preproccessing ,include remove numbers,stopwords,and chinese word segmentation
#remove numbers
removeNumbers<-function(x){
  ret=gsub("[0-9０１２３４５６７８９]","",x)
}

#textinfo$CONTENT<-lapply(textinfo$CONTENT,removeNumbers)

#word split
library(Rwordseg)
recordcount<-length(textinfo$CID)

for(i in 1:recordcount){
    cid<-textinfo$CID[i]
    content<-textinfo$CONTENT[i]
    content<-removeNumbers(content)
    content<-gsub("[\'\"]","",content)
    tokens<-segmentCN(content,nature=TRUE)
    pos<-names(tokens)
    offset<-1
    for(j in 1:length(tokens)){
      if(nchar(tokens[j])>128){
        next
      }
      if(!(tokens[j] %in% stopwords)){
        sql<-paste("insert into WEIYY_TEST.TA_SEGMENT VALUES('",cid,"','",tokens[j],"','",pos[j],"','",offset,"','')",sep="")
        offset<-offset+1
        dbSendUpdate(ch,sql)
        #print(sql)
      }
    }   
}



