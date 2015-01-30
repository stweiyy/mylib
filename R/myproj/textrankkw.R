#include package
library(parallel)
#get word matrix
textRankExtract<-function(words,slidingwindow=5,d=0.85,iter=50,topK=30){
	diffwords<-unique(words)
	diffwordsCount<-length(diffwords)
	if(diffwordsCount<slidingwindow){#for cases the number of word is too small ,just return
        #return(diffwords)
		return(paste(diffwords,collapse=","))
	}
	if(diffwordsCount<=topK){#for topk filter
        #return(diffwords)
		return(paste(diffwords,collapse=","))
	}
    #for test ,check the word frequncy
    #wordFreq<-as.data.frame(table(words))
    #print(wordFreq[order(-wordFreq$Freq),])

    #wordsDic<-hash(diffwords,1:diffwordsCount)
	#print(wordsDic)
	wordsDic<-list()
	i<-1;
	for(word in diffwords){
		wordsDic[[word]]=i;
		i<-i+1;
	}
    wordsSeq<-sapply(words,function(x){wordsDic[[x]]},USE.NAMES=FALSE)
    #matrix to store the word relation, col:src, row :distination, this is matrix is symmetrical
	wordMatrix<-matrix(0,diffwordsCount,diffwordsCount)
	for(winIdx in 1:(length(words)-slidingwindow+1)){
		wordpair<-combn(wordsSeq[winIdx:(winIdx+slidingwindow-1)],2)
		for(k in 1:ncol(wordpair)){
				w1<-wordpair[1,k];w2<-wordpair[2,k]
				wordMatrix[w1,w2]<-wordMatrix[w1,w2]+1
				wordMatrix[w2,w1]<-wordMatrix[w2,w1]+1
		}
	}
	cs<-colSums(wordMatrix)
	cs[cs==0]<-1
	delta<-(1-d)/diffwordsCount
	probMatrix<-matrix(delta,diffwordsCount,diffwordsCount)
	for(i in 1:diffwordsCount){
		probMatrix[i,]<-probMatrix[i,]+d*wordMatrix[i,]/cs
	}
	x<-rep(1,diffwordsCount)
	for(i in 1:iter){
		x<-probMatrix %*% x
	}
	wordIds<-order(x,decreasing=TRUE)[1:topK]
	wordslist<-sapply(wordIds,function(x){return(diffwords[x])},USE.NAMES=FALSE)
    #print(wordslist)
    #return(wordslist)
	return(paste(wordslist,collapse=","))
}
dfm<-read.table("articles.txt",header=FALSE,col.names=c("id","content"),stringsAsFactors=FALSE)
dfm<-dfm[nchar(dfm$content)>10,]
dfm$wordslist<-strsplit(dfm$content,",")

#textRankExtract(dfm$wordslist[[1]])
#q();
starttime<-Sys.time();
docids<-dfm$id
np<- detectCores(logical = FALSE)
np<-as.integer(np)
np<-np-2
cluster<-makeCluster(np)
docwords<-parSapply(cluster,dfm$wordslist,textRankExtract,USE.NAMES=FALSE)
stopCluster(cluster)

dfm<-data.frame(docids,unlist(docwords))
endtime<-Sys.time();
print(endtime-starttime);
write.table(dfm,"textrank_kw.txt",sep="\t",row.names=FALSE,col.names=FALSE)
