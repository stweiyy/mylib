#description:this script is used to make the training data set urls
#you define some type of keywords
#and this script will search news.yodao.com and get the related urls.

library(RCurl)
library(XML)

getUrlsFrom163<-function(keyword="",cat="",num=20,length=10){
	if(!nzchar(keyword)||is.null(keyword)||!nzchar(cat)){
		return(NULL)	
	}
	ch<-getCurlHandle()
	curlSetOpt(.opts=list(proxy="proxy.pek.sap.corp:8080"),curl=ch)
	urls<-c()
	pages<-ceiling(num/length)
	for(i in 1:pages){
		start<-(i-1)*length
		url<-paste("http://news.yodao.com/search?q=",keyword,"&start=",start,sep="")
		tryCatch({
				content<-getURL(url,.encoding="utf8",curl=ch)
				htmltree<-htmlParse(content)
				resultUrl<-xpathSApply(htmltree,'//ul[@id="results"]/li/h3/a',function(el){xmlGetAttr(el,"href")})
				},error=function(err){
				print(err)
				resultUrl<-c()
				})
		urls<-c(urls,resultUrl)
		Sys.sleep(1)
	}
	catCol<-rep(cat,length(urls))
	ret<-data.frame(url=urls,category=catCol,stringsAsFactors=FALSE)
	return(ret)
}
#x1<-getUrlsFrom163("体育","体育",30)
#x2<-getUrlsFrom163("篮球","体育",30)
#x1<-getUrlsFrom163("互联网","IT",30)
#x2<-getUrlsFrom163("程序员","IT",30)
#x1<-getUrlsFrom163("证券","财经",30)
#x2<-getUrlsFrom163("股票","财经",30)
#x1<-getUrlsFrom163("国防","军事",30)
#x2<-getUrlsFrom163("军事","军事",30)
x1<-getUrlsFrom163("娱乐","娱乐",30)
x2<-getUrlsFrom163("明星","娱乐",30)
x<-rbind(x1,x2)
write.table(x,file="training/url.txt",append=TRUE,col.names=FALSE)
