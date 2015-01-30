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

baseurl='https://api.stackexchange.com/2.2/questions'
#filter ,get as much as possible, body mark
filter='!51HTsO6iD8*Xnh90MJ6BfhQGyGR3zHJfnbW_.m'

##crawl one days questions#############################
def requestOneDay(str,startpage=1):
    maxtry=50
    import os
    isExists=os.path.exists(str)
    if not isExists:
	os.mkdir(str)
    datestr=str
    startTs=changeDateToTs(datestr)
    d=datetime.datetime.strptime(str,"%Y-%m-%d")
    endd=d+datetime.timedelta(days=1)
    endTs=int(time.mktime(d.timetuple()))

    import json

    page=startpage
    quota_remain=1
    has_more=True
    excepttimes=0

    while quota_remain>=1 and has_more :
	#if fails times larger than trymax ,quit
	if excepttimes>maxtry:
	    return
	if page==startpage:
	    logger.info("crawling %s started at page %d,please waiting..." % (str,startpage))

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

	    fn="%s/%d.json" % (str,page)
	    output=open(fn,'w')
	    output.write(data)
	    output.close()

	    if has_more==False:
		logger.info("crawling %s finished,total page %d" % (str,pageMax))
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

##########Entry Point####################################
##request limit , 1 day ,quote_max request, 1 second less 30 times
#requestOneDay("2012-12-01")


#from this time, fetch all the days before
currDay=datetime.datetime(2014,12,10)
closeDay=datetime.datetime(2014,12,1)

while (currDay-closeDay).days>=0:
    currstr=currDay.strftime('%Y-%m-%d')
    requestOneDay(currstr)
    currDay=currDay+datetime.timedelta(days=-1)

