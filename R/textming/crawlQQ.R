library("RCurl")

#set some http request header information
myhttpheader <- c(
"User-Agent"="Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-CN; rv:1.9.1.6) ",
"Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
"Accept-Language"="en-us",
"Connection"="keep-alive",
"Accept-Charset"="GB2312,utf-8;q=0.7,*;q=0.7"
)

#get the CUrl handle for lator use
ch <- getCurlHandle(httpheader = myhttpheader)
#need proxy to access the internet
curlSetOpt(.opts=list(proxy="proxy.pvgl.sap.corp:8080"),curl=ch)

loginsigurl<-"http://ui.ptlogin2.qq.com/cgi-bin/login?appid=46000101&style=13&lang=&low_login=1&hide_title_bar=1&hide_close_icon=1&&s_url=http://t.qq.com&daid=6"
content<-getURL(loginsigurl,curl=ch)
login_sig<-strsplit(strsplit(content,"login_sig")[[1]][2],",")[[1]][1]
login_sig<-strsplit(login_sig,"\"")[[1]][2]
checkurl<-paste("http://check.ptlogin2.qq.com/check?regmaster=&uin=myratingengine@163.com&appid=46000101&js_ver=10043&js_type=1&login_sig=",login_sig,"&u1=http%3A%2F%2Ft.qq.com&r=0.040177004413059714",sep="")

checkcodestr<-getURL(checkurl,curl=ch)