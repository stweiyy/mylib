#crawl web page from internet, and the url list is from XDR table
#define the log writer
#include package

library(hash)
library(RJDBC)
library(RCurl)
library(parallel)
library(Rwordseg)
#testurl<-"http://learning.sohu.com/20130517/n376285201.shtml"
#config data
confdata<-NULL
config<-NULL
tryCatch({
  confdata<-read.table("/home/R/config.ini",header=FALSE,
                       sep="=",comment.char="#",
                       stringsAsFactors =FALSE)
	config<-hash(confdata[[1]],confdata[[2]])
},error=function(){
  print("can not find the config.ini file, please edit /home/R/config.ini!")
  quit("no")
})

#for record logs
logwriter<-function(logname,msglevel="",content=""){
  fp<-file(logname,"a")
  log<-sprintf("%s  %s	%s",Sys.time(),msglevel,content)
  writeLines(log,fp)
  close(fp)
}
#filter:remove some html tags
prefilter<-function(html){
  html_tmp_content<-html
  html_tmp_content<-gsub("<!DOCTYPE.*?>","",html_tmp_content,ignore.case=TRUE)
  html_tmp_content<-gsub("<!--.*?-->","",html_tmp_content,ignore.case=TRUE)
  html_tmp_content<-gsub("<script.*?>.*?</script>","",html_tmp_content,ignore.case=TRUE)
  html_tmp_content<-gsub("<style.*?>.*?</style>","",html_tmp_content,ignore.case=TRUE)
  html_tmp_content<-gsub("&.{2,5};","",html_tmp_content,ignore.case=TRUE)
  html_tmp_content<-gsub("&#.{2,5};","",html_tmp_content,ignore.case=TRUE)
  html_tmp_content<-gsub("<link.*?/>","",html_tmp_content,ignore.case=TRUE)
  html_tmp_content<-gsub("<a.*?>.*?</a>","",html_tmp_content,ignore.case=TRUE)
  html_tmp_content<-gsub("<span.*?>|</span>","",html_tmp_content,ignore.case=TRUE)
  html_tmp_content<-gsub("<.*?>","",html_tmp_content,ignore.case=TRUE)
  html_tmp_content<-gsub("\r","",html_tmp_content,ignore.case=TRUE)
  html_tmp_content<-gsub("\\t","",html_tmp_content)
  html_tmp_content<-gsub("'","",html_tmp_content)
  html_tmp_content<-gsub('"',"",html_tmp_content)
  return (html_tmp_content)
}

#get the raw html from the url and filter useless tags
getRawHtml<-function(logname,url,proxy="",timeout=""){
  tryCatch({
    logwriter(logname,msglevel="start crawlling",content=url)
    ch<-getCurlHandle()
    if(nchar(proxy)>5){
      curlSetOpt(.opts=list(proxy=proxy),curl=ch)
    }
    if(nchar(timeout)>0){
      curlSetOpt(.opts=list(timeout=as.numeric(timeout)),curl=ch)
    }
	html<-getURL(url,.encoding="utf8",.mapUnicode=FALSE,curl=ch)
	#html<-getURL(url,.mapUnicode=FALSE,curl=ch)
	content_type<-attr(html,"Content-Type")
	if(is.null(content_type)){
		html_utf<-iconv(html,"gbk","utf8")
		if(is.na(html_utf)){
			html_utf<-html
		}
	}
	else{
		html_utf<-NA
		if(class(html)=='character'){
			if(is.na(content_type['charset'])==FALSE){
				html_utf<-iconv(html,content_type['charset'],"utf8")
			}
			if(is.na(html_utf)){
				html_utf<-iconv(html,"gbk","utf8")
			}
			if(is.na(html_utf)){
				html_utf<-iconv(html,"big5","utf8")
			}
			if(is.na(html_utf)){
				html_utf<-html
			}
		}
		else{
				html_utf<-html
		}
	}
    html<-prefilter(html_utf)
    logwriter(logname,msglevel="finish crawlling",content=url)

    return(html)
  },error=function(err){
    #print(err)
    logwriter(logname,msglevel="crawler ERROR:",content=err)
    return(NULL)#indicate failure
  },finally={gc()})
}
#read parameters from config.ini

extract<-function(content,blkwidth=5){
	lines<-unlist(strsplit(content,c('\n','\r')))
	lineTotal<-length(lines)
	if(lineTotal<blkwidth){
		logwriter(config$logname,msglevel="WARNING",content="the lineTotal<blkwidth")
		return(NULL)
	}
	#compute the chars of each line,remove blank chars
	linesCharCounter<-sapply(lines,function(x){str<-gsub("\\s*","",x);return(nchar(str))},USE.NAMES =FALSE);
	#now compute the distribution of the chars ,with argument blkwidth
	disVecLen<-lineTotal+1-blkwidth
	disVec<-integer(disVecLen)
	for(i in disVecLen:1){
		disVec[i]<-sum(linesCharCounter[i:(i+blkwidth-1)])
	}
	resultStr<-""
	#then find the max continuous area and extract the content
	starti<-0
	resultstarti<-0
	endi<-0
	resultendi<-0
	currentStr<-""
	currentmaxLen<-0
	maxLen<-0
	#print(disVec)
	flag=0
	i<-1
	while(i<=disVecLen){
		if(disVec[i]==0){
			if(flag==1){#meet the  end of the block
				flag<-0
				if(currentmaxLen>maxLen){
					resultstarti<-starti
					resultendi<-i-1
					maxLen<-currentmaxLen
					currentmaxLen<-0
				}
			}
			i<-i+1
		}
		else{
			if(flag==0){
				flag<-1 #flag==1 means a new start for search
				starti<-i
			}
			currentmaxLen<-currentmaxLen+disVec[i]
			i<-i+1
		}
	}
	#assure that index range!
	if(lineTotal>=resultstarti&&lineTotal>=(resultendi+blkwidth-1))
	{
		resultStr<-paste(lines[resultstarti:(resultendi+blkwidth-1)],collapse="")
		resultStr<-gsub("\\s+"," ",resultStr)
	}
	else{#it seems that something  error happend!
		logwriter(config$logname,msglevel="ERROR",content="the result index out of range,check function extract")
	}
	return(resultStr)
}


#get word matrix
textRankExtract<-function(content,stopwords=NULL,slidingwindow=5,d=0.85,iter=20,topK=20){
	words<-segmentCN(content)
	if(!is.null(stopwords)){
		words<-words[!(words %in% stopwords)]
	}
    #filter those not begin with chinese
	filter<-function(x){
		if(length(charToRaw(substr(x,1,1)))==3) return(x) else return(NA)
	}
    #filter and remove
	words<-sapply(words,filter,USE.NAMES=FALSE)
	words<-words[!is.na(words)]

	diffwords<-unique(words)
	diffwordsCount<-length(diffwords)
	if(diffwordsCount<slidingwindow){#for cases the number of word is too small ,just return
		return(diffwords)
	}
	if(diffwordsCount<=topK){#for topk filter
		return(diffwords)
	}
    #for test ,check the word frequncy
    #wordFreq<-as.data.frame(table(words))
    #print(wordFreq[order(-wordFreq$Freq),])

	wordsDic<-hash(diffwords,1:diffwordsCount)
	#print(wordsDic)
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
	return(wordslist)
}

#main function
main<-function(){
	jdbcDriver <- JDBC("com.sap.db.jdbc.Driver", config$jdbcpath, identifier.quote="`")
	ch <- dbConnect(jdbcDriver, paste("jdbc:sap:", config$hanaip, ":", config$hanaport, sep=""), config$uid, config$pwd)
	querysql<-sprintf("SELECT DISTINCT URL  FROM %s.TB_COM_DIM_XDR  where URL not in (SELECT DISTINCT URL from %s.TB_POI_CAL_URL_WORD) limit 100",config$schema,config$schema)
	urls<-dbGetQuery(ch,querysql)
	urlvec<-unlist(urls)
    #print(urlvec)
	querysql<-sprintf("select TOKEN from %s.TB_POI_DIM_STOPWORDS",config$schema)
	words<-dbGetQuery(ch,querysql)
	stopwords<-unlist(words$TOKEN)

    #cpunum<-detectCores() 
	v<-lapply(urlvec,function(url){
			  print(sprintf("start handle %s",url))
		      content<-getRawHtml(config$logname,url,proxy=config$proxy,timeout=config$timeout)
	   		  if(is.null(content)||!nzchar(content)) return(NULL)
		      content<-extract(content,blkwidth=5)
		      if(!nzchar(content)||is.null(content)){
			    logwriter(config$logname,msglevel="WARNING",content="result from extract is null or empty")
		   	    return(NULL)
		      }
			  if(nchar(content)<20){#filter those too short content
			    logwriter(config$logname,msglevel="WARNING",content=content)
				return(NULL)
			  }
			  if(length(grep("copyright",content,ignore.case=TRUE))>0){
				logwriter(config$logname,msglevel="WARNING",content=content)
				return(NULL)
			  }
			  if(length(grep("Moved",content,ignore.case=TRUE))>0){
				logwriter(config$logname,msglevel="WARNING",content=content)
				return(NULL)
			  }
			  keywords<-textRankExtract(content,stopwords,topK=50)
              #print(keywords)
              #return(NULL)
			  if(!is.null(keywords)&&length(keywords)>0){
					for(word in keywords){
						tryCatch({
								 if(nchar(word)<2) next
								 upsertstat<-sprintf("insert into %s.TB_POI_CAL_URL_WORD VALUES('%s','%s','%s')",config$schema,url,word,Sys.Date())
								 print(upsertstat)
								 dbSendUpdate(ch,upsertstat)
								 logwriter(config$logname,msglevel="INSERT SUCCESS:",content=upsertstat)
								},error=function(e){
							    print(e)
								logwriter(config$logname,msglevel="SQL ERROR:",content=e)
								})
					}
			  }
	})
            dbDisconnect(ch)
}
main()
