library("RCurl")
library("rjson")

#authinfo ,username and password
authinfo<-c("username"="myratingengine@163.com","password"="abcd1234")

#set some http request header information
myHttpheader <- c(
"User-Agent"="Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-CN; rv:1.9.1.6) ",
"Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
"Accept-Language"="en-us",
"Connection"="keep-alive",
"Accept-Charset"="GB2312,utf-8;q=0.7,*;q=0.7"
)

#get the CUrl handle for lator use
cHandle <- getCurlHandle(httpheader = myHttpheader)
#need proxy to access the internet
curlSetOpt(.opts=list(proxy="proxy.pvgl.sap.corp:8080"),curl=cHandle)

d<-debugGatherer()

#login step
authresult<- postForm("https://reg.163.com/logins.jsp",.opts=list(debugfunction=d$update,verbose=TRUE,ssl.verifypeer=FALSE),curl=cHandle,.params=authinfo)
#cat(d$value()[2])

#search params
searchMethod<-function(keyword,page=1){
	searchParams<-c("k"=keyword,"pageMethod"="page","pageNo"=page,"t"="ALL","ta"="al")
	content<- postForm("http://t.163.com/search.do?action=searchTweet",.opts=list(debugfunction=d$update,verbose=TRUE),curl=cHandle,.params=searchParams,style="post")
	return(content)
}

#parse the content
htmlInfo<-searchMethod(keyword="china",page=1)
jsonStr<-gsub(pattern="\r\n",replacement="",htmlInfo[1])
jsonInfo<-fromJSON(jsonStr[1])
weiboRecord<-jsonInfo$list
content<-unlist(lapply(weiboRecord,function(x){x$content}))
timeStamp<-unlist(lapply(weiboRecord,function(x){x$timestamp}))
replyCount<-unlist(lapply(weiboRecord,function(x){x$replyCount}))
retweetCount<-unlist(lapply(weiboRecord,function(x){x$retweetCount}))
sourceinfo<-unlist(lapply(weiboRecord,function(x){x$source}))

weibo<-data.frame(content=content,time=timeStamp,replyCount=replyCount,retweetCount=retweetCount,source=sourceinfo)

#Sys.setlocale(locale="Chinese")
