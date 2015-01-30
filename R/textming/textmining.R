Sys.setlocale(,"CHS")
library("RJDBC")
port = "30115"
host = "10.128.84.31"
uid = "SYSTEM"
pwd = "manager"
jdbcDriver <- JDBC("com.sap.db.jdbc.Driver", "C:\\Program Files\\sap\\hdbclient\\ngdbc.jar", identifier.quote="`")
ch <- dbConnect(jdbcDriver, paste("jdbc:sap:", host, ":", port, sep=""), uid, pwd)
#step(1): fetch data from database
textinfo <- dbGetQuery(ch, "select CID,CONTENT from GW.COMMENTS limit 100")

#step(2):preproccessing ,include remove numbers,stopwords,and chinese word segmentation
#remove numbers
removeNumbers<-function(x){
  ret=gsub("[0-9０１２３４５６７８９]","",x)
}
textinfo$CONTENT<-lapply(textinfo$CONTENT,removeNumbers)

#word split
library(Rwordseg)
wordsegment<-function(x){
  segmentCN(x)
}
textinfo$CONTENT<-lapply(textinfo$CONTENT,wordsegment)
#remove stop words
stopwords<-unlist(read.table("C:\\Users\\I302308\\Documents\\R\\corpus\\chinesestop.txt",stringsAsFactors=F,quote=""))
removeStopwords<-function(x,words){
  ret=character(0)
  index<-1
  it_max<-length(x)
  while(index<=it_max){
    if(length(words[words==x[index]])<1){
      ret<-c(ret,x[index])
    }
    index<-index+1
  }
  return(ret)
}
textinfo$CONTENT<-lapply(textinfo$CONTENT,removeStopwords,stopwords)
#construct corpus
library("tm")
corpus<-Corpus(VectorSource(textinfo$CONTENT))
meta(corpus,"commentid")<-textinfo$CID

#construct word-document matrix
dtm<-DocumentTermMatrix(corpus,control=list(wordLengths=c(2,Inf)))

#wordcloud photo demo
library("wordcloud")
m<-as.matrix(dtm)
v<-sort(colSums(m),decreasing=TRUE)
d<-data.frame(word=names(v),freq=v)

#word cloud
wordcloud(d$word,d$freq,scale=c(6,1.5),
          min.freq=2,max.words=20,random.order=FALSE,
          colors=rainbow(100))

#kmeans cluster
#kmresult<-kmeans(m,4)
#层次聚类
#hr<-hclust(dist(m),method="ave")
#plot(hr,hang=-1)
