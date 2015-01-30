name<-"myratingengine@163.com";
pwd<-"1qaz2wsx"

memory.limit(4000)
library(RCurl)
library(digest)

#username pre-processing
name<-gsub('@','%40',name)
name<-base64(name)[1]

myheader<-c(
"Host"="login.sina.com.cn",
"User-Agent"="Mozilla/5.0 (Windows NT 5.1; rv:2.0.1) Gecko/20100101 Firefox/4.0.1",
"Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
"Accept-Language"="zh-cn,zh;q=0.5",
"Accept-Encoding"="gzip, deflate",
"Accept-Charset"="GB2312,utf-8;q=0.7,*;q=0.7",
"Keep-Alive"="115",
"Connection"="keep-alive",
"Referer"="http://weibo.com/",
"Content-Type"="application/x-www-form-urlencoded; charset=UTF-8"
)
d=debugGatherer()
ch=getCurlHandle(
debugfunction=d$update,verbose=T,
ssl.verifyhost=F,ssl.verifypeer=F,
followlocation=T,
cookiefile="cookie.txt")

##get the parameters needed later.
preurl=paste("http://login.sina.com.cn/sso/prelogin.php?entry=weibo&callback=sinaSSOController.preloginCallBack&su=",name,"&rsakt=mod&client=ssologin.js(v1.4.11)",sep='')
#the below use the environment's proxy
#prelogin<-readLines(preurl,warn=F)
#set the proxy server,or can not access the internet
curlSetOpt(.opts=list(proxy="proxy.pvgl.sap.corp:8080"),curl=ch)
prelogin<-getURL(preurl,curl=ch)

matches<-gregexpr('servertime\":(\\d+)',prelogin,perl=TRUE)
servertime<-substr(prelogin,attr(matches[[1]],'capture.start'),attr(matches[[1]],'capture.start')+attr(matches[[1]],'capture.length')-1)

matches<-gregexpr('nonce\":\"([0-9A-Za-z]+)\"',prelogin,perl=TRUE)
nonce<-substr(prelogin,attr(matches[[1]],'capture.start'),attr(matches[[1]],'capture.start')+attr(matches[[1]],'capture.length')-1)

matches<-gregexpr('rsakv\":\"(\\d+)',prelogin,perl=TRUE) 
rsakv<-substr(prelogin,attr(matches[[1]],'capture.start'),attr(matches[[1]],'capture.start')+attr(matches[[1]],'capture.length')-1)

rsaserviceurl<-paste('http://10.128.84.31:8001/weiyy/test/RSA2encrypt.xsjs?nonce=',nonce,'&servertime=',servertime,sep='')
password<-getURL(rsaserviceurl,curl=ch)

postparams<-c(
	"encoding"="UTF-8",
	"entry"="weibo",
	"from"="",	
	"gateway"="1",
	"nonce"=nonce,
	"pagerefer"="http://www.weibo.com/a/download",
	"prelt"="858",
	"pwencode"="rsa2",
	"returntype"="META",
	"rsakv"=rsakv,
	"savestate"="7",
	"servertime"=servertime,
	"service"="miniblog",
	"sp"=password,
	"su"=name,
	"url"="http://www.weibo.com/ajaxlogin.php?framelogin=1&callback=parent.sinaSSOController.feedBackUrlCallBack",
	"useticket"="1",
	"vsnf"="1"
)
ssourl<-"http://login.sina.com.cn/sso/login.php?client=ssologin.js(v1.4.11)"
Sys.setlocale('LC_ALL','C')
response<-postForm(ssourl,httpheader=myheader,.params=postparams,curl=ch,style="post")
response
