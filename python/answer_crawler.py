#!/usr/bin/python
import urllib2
import zlib,gzip
import StringIO
import time
import datetime
import sys
import logging

##prepare the logger###################################
logger=logging.getLogger('crawl-logger')
logger.setLevel(logging.INFO)
fh=logging.FileHandler('info.log')
fh.setLevel(logging.INFO)
ch=logging.StreamHandler()
ch.setLevel(logging.INFO)
formatter= logging.Formatter('%(asctime)s - %(name)s - %(levelname)s: %(message)s')
fh.setFormatter(formatter)
ch.setFormatter(formatter)
logger.addHandler(fh)
logger.addHandler(ch)
######################################################

##change the date like '2012-04-04' to unix timestamp##
def changeDateToTs(datestr):
    d=datetime.datetime.strptime(datestr,"%Y-%m-%d")
    return int(time.mktime(d.timetuple()))
#######################################################

##get the content of the URL,then uncompress############
def getURLContent(url):
    data=""
    try:
	request=urllib2.Request(url)
	proxy=urllib2.ProxyHandler({'https':'http://proxy.pek2.sap.corp:8080'})
	request.add_header('Accept-encoding','gzip')
	opener=urllib2.build_opener(proxy)
	response=opener.open(request)
	data=response.read()
	response.close()
	#uncompress the gzip content
	cpss=StringIO.StringIO(data)
	gziper=gzip.GzipFile(fileobj=cpss)
	dataucp=gziper.read()
	logger.info(url+"\tsuccess!")
	return dataucp
    except Exception,e:
	if isinstance(e,urllib2.HTTPError):
	    msg=url,":HTTP ERROR, error code ",e.code
	    logger.info(msg)
	elif isinstance(e,urllib2.URLError):
	    if hasattr(e,'reason'):
		msg=url,':URL Error,Reason:',e.reason
	    elif hasattr(e,'code'):
		msg=url,':URL Error,code:',e.code
	    else:
		msg=url,':Other URL Error'
	    logger.info(msg)
	else:
	    msg=url,":other Exception"
	    logger.info(msg)
	return None

#######################################################

baseurl='https://api.stackexchange.com/2.2/answers'
#filter ,get as much as possible, body mark
filter='!)rCcHAH6zRsEZsmSjJKi'

##crawl one days questions#############################
def requestOneDay(str,startpage=1):
    maxtry=50
    import os
    isExists=os.path.exists(str)
    if not isExists:
	os.mkdir(str)
    datestr=str
    startTs=changeDateToTs(datestr)
    if os.path.isfile(str+"/timestamp.txt"):
	fp=open(str+"/timestamp.txt")
	line=fp.readline()
	t=datetime.datetime.strptime(line,"%Y-%m-%d %H:%M:%S")
	startTs=int(time.mktime(t.timetuple()))
	fp.close()
    d=datetime.datetime.strptime(str,"%Y-%m-%d")
    endd=d+datetime.timedelta(days=1)
    endTs=int(time.mktime(endd.timetuple()))
    import json

    allfileno=os.listdir(str)
    allfileno=[int(os.path.splitext(x)[0]) for x in allfileno if x.endswith("json")]
    if len(allfileno):
	nextfileno=max(allfileno)+1
    else:
	nextfileno=1

    page=startpage
    quota_remain=1
    has_more=True
    excepttimes=0

    while quota_remain>=1 and has_more :
	#if fails times larger than trymax ,quit
	if excepttimes>maxtry:
	    return
	if page==startpage:
	    timestr=time.strftime("%Y-%m-%d %H:%M:%S",time.localtime(startTs))
	    logger.info("crawling %s started at page %d, fileno at %d,please waiting..." % (timestr,startpage,nextfileno))

	url="%s?key=DVAeKoca7FUJr)qir*FmeA((&page=%d&pagesize=100&fromdate=%d&todate=%d&order=desc&sort=activity&site=stackoverflow&filter=%s" % (baseurl,page,startTs,endTs,filter)
	st=time.time()
	data=getURLContent(url)

	if data:
	    try:
		jsonobj=json.loads(data)
	    except Exception,e:
		excepttimes=excepttimes+1
		msg=url,"Json Exception,",e
		logger.info(msg)
		continue

	    quota_remain=jsonobj["quota_remaining"]
	    has_more=jsonobj["has_more"]

	    if len(jsonobj["items"])>0:
		fn="%s/%d.json" % (str,nextfileno)
       	        output=open(fn,'w')
	        output.write(data)
	        output.close()

	    if has_more==False:
		timeinfo=time.strftime("%Y-%m-%d %H:%M:%S",time.localtime())
		logger.info("crawling %s finished,at %s" % (str,timeinfo))
		fp=open(str+"/timestamp.txt","w")
		fp.write(timeinfo)
		fp.close()
		return

	    #if one day send more than quota_max req, then sleep until next day
	    if quota_remain<=1:
		nowdate=datetime.datetime.now()
		year=datetime.datetime.now().year
		month=datetime.datetime.now().month
		day=(nowdate+datetime.timedelta(days=1)).day
		newstart=datetime.datetime(year,month,day)
		sleepsec=(newstart-datetime.datetime.now()).seconds
		logger.info("sleep for %d seconds!" %(sleepsec))
		time.sleep(sleepsec)
	#means that data is not true ,some error happend
	else:
	    excepttimes=excepttimes+1

	et=time.time()
	elapse=et-st
	if elapse<0.1:
	    time.sleep(1)
	page=page+1
	nextfileno=nextfileno+1
##########Entry Point####################################
##request limit , 1 day ,quote_max request, 1 second less 30 times

timeday=time.strftime("%Y-%m-%d", time.localtime()) 
requestOneDay(timeday)

