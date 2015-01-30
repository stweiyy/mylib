
name="myratingengine@163.com";pwd="1qaz2wsx"

memory.limit(4000)
library(RCurl)
library(digest)


name=gsub('@','%40',name)
name=base64(name)[1]

myH=c(
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
curl=getCurlHandle(
debugfunction=d$update,verbose=T,
ssl.verifyhost=F,ssl.verifypeer=F,
followlocation=T,
cookiefile="cc.txt")

curlSetOpt(.opts=list(proxy="proxy.pvgl.sap.corp:8080"),curl=curl)

preurl=paste("http://login.sina.com.cn/sso/prelogin.php?entry=miniblog&callback=sinaSSOController.preloginCallBack&su=",name,"&client=ssologin.js(v1.4.11)",sep='')
prelogin=readLines(preurl,warn=F)


servertime=strsplit(prelogin,'\"servertime\":')[[1]][2]
servertime=strsplit(servertime,',\"pcid\"')[[1]][1]
pcid=strsplit(prelogin,'\"pcid\":\"')[[1]][2]
pcid=strsplit(pcid,'\",\"nonce\"')[[1]][1]
nonce=strsplit(prelogin,'\"nonce\":\"')[[1]][2]
nonce=strsplit(nonce,'\"}')[[1]][1]
servertime
pcid
nonce

pwd1=digest(pwd,algo='sha1',seria=F)
pwd2=digest(pwd1,algo='sha1',seria=F)
pwd3=digest(paste(pwd2,servertime,nonce,sep=''),algo='sha1',seria=F)

pinfo=c(
"service"="miniblog",
"client"="ssologin.js(v1.3.18)",
"entry"="weibo",
"encoding"="UTF-8",
"gateway"="1",
"savestate"="7",
"from"="",
"useticket"="1",
"su"=name,
"servertime"=servertime,
"nonce"=nonce,
"pwencode"="wsse",
"sp"=pwd3,
"vsnf"="1",
"vsnval"="",
"pcid"=pcid,
"url"="http://weibo.com/ajaxlogin.php?framelogin=1&callback=parent.sinaSSOController.feedBackUrlCallBack",
"returntype"="META",
"ssosimplelogin"="1",
"setdomain"="1"
)

ttt=postForm("http://login.sina.com.cn/sso/login.php?client=ssologin.js(v1.4.11)",
httpheader=myH,.params=pinfo,curl=curl,style="post")


newurl=strsplit(ttt[1],'location.replace[(]\'')[[1]][2]
newurl=strsplit(newurl,'\');')[[1]][1]
print(newurl)