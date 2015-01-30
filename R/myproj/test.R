library(tm);
dfm<-read.table("articles.txt",header=FALSE,col.names=c("id","content"),stringsAsFactors=FALSE)
#filter the empty document and those has less than 10 words
dfm<-dfm[nchar(dfm$content)>10,]
dfm$wordslist<-strsplit(dfm$content,",")
corpus<-Corpus(VectorSource(dfm$wordslist))
meta(corpus,"MetaID")<-dfm$id
dtm<-DocumentTermMatrix(corpus,control=list(wordLengths=c(2,Inf),weighting=function(x)weightTfIdf(x)))
dtm<-removeSparseTerms(dtm,0.999)
print(dtm)

q();

