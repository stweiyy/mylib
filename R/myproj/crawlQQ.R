library(RCurl)
library(digest)

login_sig_url<-"http://ui.ptlogin2.qq.com/cgi-bin/login?appid=46000101&style=13&lang=&low_login=1&hide_title_bar=1&hide_close_icon=1&&s_url=http://t.qq.com&daid=6"
ch<-getCurlHandle()
curlSetOpt(.opts=list(proxy="proxy.pvgl.sap.corp:8080"),curl=ch)
content<-getURL(login_sig_url,curl=ch)
content;
