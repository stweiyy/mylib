#include the webbase.R 
source(file="webbase.R")
#main function
main<-function(logfile="/home/R/log/insertwords.log"){
	jdbcDriver <- JDBC("com.sap.db.jdbc.Driver", config$jdbcpath, identifier.quote="`")
	ch <- dbConnect(jdbcDriver, paste("jdbc:sap:", config$hanaip, ":", config$hanaport, sep=""), config$uid, config$pwd)
    #querysql<-sprintf("SELECT DISTINCT 'http://'||HOST_NAME||'/'||URI as URL  FROM %s.TB_COM_DIM_XDR limit 5",config$schema)
    #urls<-dbGetQuery(ch,querysql)
	urls<-read.table("/home/R/training/url.txt",header=FALSE,stringsAsFactors =FALSE)
	names(urls)<-c("url","categoryname")
    #print(urls)

    #urls<-urls[1:10,]
    #print(urls)
    #to get the chinese stop words from the database TELECOM,schema TB_POI_DIM_STOPWORDS
	cpunum<-detectCores() 
	querysql<-sprintf("select TOKEN from %s.TB_POI_DIM_STOPWORDS",config$schema)
	words<-dbGetQuery(ch,querysql)
	stopwords<-unlist(words$TOKEN)
    #print(stopwords)

    #set the log file
	config$logname<-logfile
    #change the schema name
	config$schema="WEIYY_TEST"

	v<-mapply(function(url,categoryname){
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
              #print(content)
			  keywords<-textRankExtract(content,stopwords,topK=50)
              #print(keywords)
			  if(!is.null(keywords)&&length(keywords)>0){
					for( word in keywords){
					  tryCatch({
							#for those one Char ,here we ignore
							if(nchar(word)<2) next	
							upsertstat<-sprintf("UPSERT %s.TRAININGSET VALUES('%s','%s') where word ='%s'",config$schema,word,categoryname,word)
							print(upsertstat)
                            dbSendUpdate(ch,upsertstat)
					        logwriter(config$logname,msglevel="UPSERT SUCCESS:",content=upsertstat)
				            },error=function(e){
							print(e)
				            logwriter(config$logname,msglevel="SQL ERROR:",content=e)

			          })
				    }
			  }
		      return(TRUE)
	        },urls$url,urls$categoryname)

            dbDisconnect(ch)
}
main()
