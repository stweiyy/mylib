library(RCurl)
library(XML)
myhttpheader <- c(
"User-Agent"="Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-CN; rv:1.9.1.6) ",
"Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
"Accept-Language"="zh-ch,zh;q=0.8,en-us;q=0.5,en;q=0.3",
"Connection"="keep-alive",
"Accept-Charset"="GBK,utf-8;q=0.7,*;q=0.7"
)

loginurl<-"http://passport.sohu.com/sso/login.jsp?userid=myratingengine%40163.com&password=1c63129ae9db9c60c3e8aa94d3e00495&appid=1073&persistentcookie=0&isSLogin=1&s=1378811384968&b=2&w=1600&pwdtype=1&v=26"

ch<-getCurlHandle()
curlSetOpt(.opts=list(proxy="proxy.pvgl.sap.corp:8080"),curl=ch)
curlSetOpt(cookiejar="cookies.txt",useragent ="Mozilla/5.0",followlocation = TRUE,curl=ch)
loginfo<-getURL(loginurl,curl=ch)

urlencodegbk<-function(keyword){
	encodepoint<-unlist(strsplit(keyword,""))
	codechars<-lapply(encodepoint,function(x){iconv(encodepoint,from="UTF-8",to="GBK")})[[1]]
	urlencode<-unlist(lapply(codechars,function(x){curlEscape(x)}))
	encodestr<-paste(urlencode,collapse="")
	return(encodestr)
}

getsearchpage<-function(keyword,pageno=1){
	tryCatch({
		gbkkeyword<-urlencodegbk(keyword)
		urladdr<-paste("http://t.sohu.com/twsearch/twSearch?key=",gbkkeyword,"&pageNo=",pageno,sep="")
		content<-getURL(urladdr,curl=ch,.encoding="UTF-8")
		htmltree<-htmlParse(content,encoding="GBK")
		weibocollect<-xpathSApply(htmltree,'//div[@class="twi "]',xmlValue)
		weibocollecthaspic<-xpathSApply(htmltree,'//div[@class="twi twiHasPic "]',xmlValue)
		myfilter<-function(x){tmp<-gsub(pattern="\r\n",replacement="",x);gsub(pattern="\t",replacement="",tmp)}
		weibocollect<-unlist(lapply(weibocollect,myfilter))
		weibocollecthaspic<-unlist(lapply(weibocollecthaspic,myfilter))
		weibolist<-c(weibocollect,weibocollecthaspic)
		return(weibolist)
	},error=function(e){
		print(e)
		return(c())
	},warning=function(e){
		return(c())
	}
	)	
}
pageno<-1
keyword<-"japan"
crawltime<-3
pagecount<-0

sohuweibo<-c()
gbkkeyword<-urlencodegbk(keyword)
urladdr<-paste("http://t.sohu.com/twsearch/twSearch?key=",gbkkeyword,"&pageNo=",pageno,sep="")
content<-getURL(urladdr,curl=ch,.encoding="UTF-8")
htmltree<-htmlParse(content,encoding="GBK")
pagecount<-max(xpathSApply(htmltree,'//a[@class="pg crjs_pg"]',xmlValue))

starttime<-as.numeric(Sys.time())
currenttime<-as.numeric(Sys.time())
pageno<-0

while(currenttime-starttime<crawltime){
	pageno<-pageno+1
	if(pageno>pagecount){break}
	tmpsohuweibo<-getsearchpage(keyword,pageno=1)
	sohuweibo<-c(sohuweibo,tmpsohuweibo)
	currenttime<-as.numeric(Sys.time())
	Sys.sleep(0.5)
}
queryword<-rep(keyword,length=length(sohuweibo))
tempout<-as.data.frame(cbind(queryword,sohuweibo))
