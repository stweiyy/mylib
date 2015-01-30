package crawler;
import java.io.*;
import java.net.*;
import java.util.logging.*;
import java.util.Date;
import java.text.*;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.TimeZone;
import java.util.zip.GZIPInputStream;

import org.json.*;

public class StofCrawler implements Runnable{
	//private  String loggerName="Crawler_log";
	/*if one request fail, we will retry, this is the retry times */
	private int singleURLTryTimes=5;
	private int sleephours=1;
	/*base url for crawling */
	//private String baseUrl="https://api.stackexchange.com/2.2/answers";
	/*filter */
	//private String filter="!)rCcHAH6zRsEZsmSjJKi";
	private String baseUrl;
	private String filter;
	/* answers or questions */
	private String crawlerType;
	
	private  Logger log;
	
	/*construct the logger*/
	public StofCrawler(String baseUrl,String filter,String ctype){
		this.baseUrl=baseUrl;
		this.filter=filter;
		this.crawlerType=ctype;
		String loggername=ctype+"-logger";
		log=Logger.getLogger(loggername);
		/*create the directory if not exists*/
		File fp=new File(ctype);
		if(!fp.exists()){
			fp.mkdirs();
		}
		/* the log file */
		String logfile=this.crawlerType+File.separatorChar+"crawler_log.txt";
		Handler fileHandler=null;
		/* set the log file */
		try{
			fileHandler=new FileHandler(logfile);
		}catch(Exception e){
			e.printStackTrace();
			System.exit(-1);
		}
		fileHandler.setFormatter(new SimpleFormatter());
		log.addHandler(fileHandler);
		log.info("Starting Crawler ....");
	}
	/*format the unix time stamp */
	public String formatTs(long ts){
		SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		return format.format(new Date(ts*1000));	
	}

	/*Handle each url and get the content, max try singleURLTryTimes */
	public String handleURLAddr(String urladdr){
		int i=1;
		String result="";
		for(i=1;i<=this.singleURLTryTimes;i++){
			result=getURLContent(urladdr);
			if(result!=""){
				return result;
			}
			try{
				Thread.sleep(3000);
			}catch(Exception e){
				e.printStackTrace();
			}	
		}
		return result;
	}
	/*get the content of the url */
	private  String getURLContent(String urladdr){
		log.info("get URL:"+urladdr);
		String result="";
		try{
			URL url=new URL(urladdr);
			HttpURLConnection httpClientConnection=(HttpURLConnection) url.openConnection();
			httpClientConnection.addRequestProperty("Accept-Encoding", "gzip");
			httpClientConnection.addRequestProperty("Connection", "close"); 
		    httpClientConnection.setRequestMethod("GET");  
		    httpClientConnection.connect();  
		    int rescode=httpClientConnection.getResponseCode();
		    //request is success, rescode=200
		    if(rescode==200){
		    	 BufferedReader bufferedReader=null;  
				 InputStream inputStream=null;  
				 try{
					  if(httpClientConnection.getContentEncoding()!=null){
						  String encode=httpClientConnection.getContentEncoding().toLowerCase();
						  if(encode.indexOf("gzip") >= 0){
								//uncompress gzip
						  inputStream = new GZIPInputStream(httpClientConnection.getInputStream());
						  }else{
							  inputStream = httpClientConnection.getInputStream(); 
						  }
					  }
					  if(inputStream!=null){
						  bufferedReader = new BufferedReader(new InputStreamReader(inputStream,"UTF-8")); 
						  String line = null; 
						  while ((line = bufferedReader.readLine()) != null) { 
						 	result+=line;
						  } 
					  }
				 }catch(Exception e){
					 result=null;
					 log.log(Level.SEVERE,e.getMessage());
				 }
				 if(inputStream!=null) inputStream.close();
				 if(bufferedReader!=null) bufferedReader.close();
		    }
		    httpClientConnection.disconnect();
		    
		}catch(Exception e){
			e.printStackTrace();
			log.log(Level.SEVERE,e.getMessage());
			result="";
		}
		return result;
	}

	private static int getNextFileNo(String dirName){
		int ret=1;
		ArrayList<Integer> alist=new ArrayList<Integer>();
		
		File dirFile=new File(dirName);
		String[] files=dirFile.list();
		
		for(int i=0;i<files.length;i++){
			String filename=files[i];
			int dot=filename.lastIndexOf(".json");
			if((dot>-1)&&(dot<(filename.length()))){
				String numn=filename.substring(0,dot);
				alist.add(new Integer(Integer.parseInt(numn)));
			}
		}
		if(alist.size()>0){
			ret=Collections.max(alist)+1;
		}
		return ret;
	}
	/*request one days's data */
	public void requestOneDay(String datestr){
		log.info("crawling date "+datestr);
		String dirName=this.crawlerType+File.separatorChar+datestr;
		File fp=new File(dirName);
		if(!fp.exists()){
			fp.mkdirs();
		}
		try{
			SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd");
			Date date=format.parse(datestr);
			/* setting start and end timestamp */
			long daystamp=(long)date.getTime()/1000;
			long startedTs=daystamp;
			/*time correction if run in local*/
			//long startedTs=(long)date.getTime()/1000+(long)TimeZone.getDefault().getRawOffset()/1000;
			
			long endedTs=daystamp+1*24*3600;
			/*to see if there is time a record file */
			File timerecord=new File(dirName+File.separatorChar+"timestamp.txt");
			if(timerecord.exists()){
				InputStreamReader reader=new InputStreamReader(new FileInputStream(timerecord));
				BufferedReader br=new BufferedReader(reader);
				String line=br.readLine();
				//format = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
				/* new start point*/
				//date=format.parse(line);
				startedTs=Long.parseLong(line);
				startedTs+=1;
				//startedTs=(long)date.getTime()/1000;
				/*time correction  */
				//startedTs=(long)date.getTime()/1000+(long)TimeZone.getDefault().getRawOffset()/1000;
				br.close();
				reader.close();
			}
			
			int nextfileno=getNextFileNo(dirName);
			int page=1;
			int quota_remain=1;
			boolean has_more=true;
			
			
			/*if nextfileno==1, then no file has crawled,then we reset the start ts to daystamp*/
			if(nextfileno==1){
				startedTs=daystamp;
			}
			log.info("started timestamp "+startedTs+" : "+formatTs(startedTs)+", ended timestamp "+endedTs+" : "+formatTs(endedTs));
			
			long maxTs=startedTs;
			while(quota_remain>=1&&has_more==true){
				
				if(page==1){
					log.info("crawling started at page "+page+" ,file no at "+nextfileno+" ,please wait...");	
				}
				/*sort by create date timestamp desc */
				String urladdr=String.format("%s?key=DVAeKoca7FUJr)qir*FmeA((&page=%d&pagesize=100&fromdate=%d&todate=%d&order=desc&sort=creation&site=stackoverflow&filter=%s", baseUrl,page,startedTs,endedTs,filter);
				
				//System.out.println(urladdr);
				String data=handleURLAddr(urladdr);
				if(data!=""){
					//System.out.println(data);
					JSONObject jb=new JSONObject(data);
					
					/* loop condition */
					quota_remain=jb.getInt("quota_remaining");
					has_more=jb.getBoolean("has_more");
					
					JSONArray items=jb.getJSONArray("items");
				    /*if have items ,then write the data*/
					if(items.length()>0){
						JSONObject jobj=items.getJSONObject(0);
						long itemts=jobj.getLong("creation_date");
						if(itemts>maxTs){
							maxTs=itemts;
							log.info("update max timestamp,maxTimeStamp:"+maxTs);
						}
						//System.out.println("time stamp is "+itemts);
						String filename=dirName+File.separatorChar+nextfileno+".json";
						writeFile(data,filename);
					}
					/*if does not have more */
					if(has_more==false){	
					    String fn=dirName+File.separatorChar+"timestamp.txt";
					    /*record the current time ,then return */
					    String fcontent=String.valueOf(maxTs);
					    writeFile(fcontent,fn);
					    return;
					}
					/*quoto_remain <=0, then just sleep to the second day*/
					if(quota_remain<=0){
						/* sleep time */
						Date d=new Date();
						@SuppressWarnings("deprecation")
						int s=1*24*3600-(d.getHours()*3600+d.getMinutes()*60+d.getSeconds());
						try{
							log.info("crawler will sleep to second day,sleep "+s+" seconds");
							Thread.sleep(s*1000);
						}catch(Exception e){
							e.printStackTrace();
						}	
					}
					
				}
				
				page+=1;
				nextfileno+=1;
				
			}
			
		}catch(Exception e){
			log.log(Level.SEVERE,e.getMessage());
			e.printStackTrace();
		}
		
	}
	
	public  void writeFile(String content,String fn){
		try{
			FileWriter writer=new FileWriter(fn);
			writer.write(content);
			writer.close();
		}catch(Exception e){
			e.printStackTrace();
			log.log(Level.SEVERE,e.getMessage());
		}
	}
	public void run(){
		
		/* Start from 2014-01-01 */
		String startDate="2015-01-01";
		String crawlday=startDate;
		
		SimpleDateFormat fr = new SimpleDateFormat("yyyy-MM-dd");
		String currentDate=fr.format(new Date());
		//System.out.println(currentDate);
		
		int exceptimes=0;
		/*crawl the previous day if not crawled */
		while(!crawlday.equals(currentDate)){
			/*we only crawl questions for the revious day*/
			if(!this.crawlerType.equals("questions")){
				break;
			}
			System.out.println(crawlday);
			File dayfiles=new File(crawlday);
			if(!dayfiles.exists()){
				this.requestOneDay(crawlday);
			}
			try {
				Date crawldaydate=fr.parse(crawlday);
				Calendar cld=Calendar.getInstance();
				cld.setTime(crawldaydate);
				cld.add(Calendar.DATE, 1);
				crawldaydate=cld.getTime();
				crawlday=fr.format(crawldaydate);
				
			}
			catch (ParseException e) {
				exceptimes+=1;
				// TODO Auto-generated catch block
				e.printStackTrace();
				if(exceptimes>20){
					System.out.println("error!!!!!!!!");
					break;
				}
				
			}	
		}
		
		/*crawl the now day */
		try{
			/*yesterday update flag*/
			boolean yesterdayupdated=false;
			
			while(true){
				/*at 18:00 ,we update the previous day of questions*/ 
				Calendar cal = Calendar.getInstance(); 
				int hours=cal.get(Calendar.HOUR_OF_DAY);
				/*only for questions*/
				if(hours>=18 && this.crawlerType.equals("questions")&&yesterdayupdated==false){		
					Date curdate=fr.parse(currentDate);
					Calendar cld=Calendar.getInstance();
					cld.setTime(curdate);
					cld.add(Calendar.DATE, -1);
					Date yesterday=cld.getTime();
					String yesterdaystr=fr.format(yesterday);
					log.info("update previous day of questions:"+yesterdaystr);
					
					String dirName=this.crawlerType+File.separatorChar+yesterdaystr;
					
					/*first delete yesterday file*/
					File fp=new File(dirName);
					if(fp.exists()&&fp.isDirectory()){
						File[] files=fp.listFiles();
						for(File subfile:files){
							subfile.delete();
						}
						fp.delete();
					}
					this.requestOneDay(yesterdaystr);
					log.info("update yesterday finished:"+yesterday);
					yesterdayupdated=true;
				}
				
				this.requestOneDay(currentDate);
				/*sleep 5 hours */
				log.info("crawler will sleep "+this.sleephours+" hours before next wake up");
				Thread.sleep(this.sleephours*3600*1000);
				log.info("crawler wake up!!!");
				/*update yesterdayupdated*/
				Date newday=new Date();
				if(!currentDate.equals(fr.format(newday))){
					yesterdayupdated=false;
				}
				currentDate=fr.format(new Date());	
			}
		}catch(Exception e){
			e.printStackTrace();
		}
	}

	public int getSleephours() {
		return sleephours;
	}
	public void setSleephours(int sleephours) {
		this.sleephours = sleephours;
	}
	
	public static void main(String[] args) {
		//set proxy
		System.setProperty("https.proxyHost", "proxy.sin.sap.corp");  
		System.setProperty("https.proxyPort", "8080");  
		
		StofCrawler answers_crawler=new StofCrawler("https://api.stackexchange.com/2.2/answers","!)rCcHAH6zRsEZsmSjJKi","answers");
		StofCrawler questions_crawler=new StofCrawler("https://api.stackexchange.com/2.2/questions","!51HTsO6iD8*Xnh90MJ6BfhQGyGR3zHJfnbW_.m","questions");
		StofCrawler comments_crawler=new StofCrawler("https://api.stackexchange.com/2.2/comments","!b0OfNZ*zgk4ppA","comments");
		
		if(args.length>0){
			System.out.println("seting sleep hours "+args[0]);
			int sleephours=Integer.parseInt(args[0]);
			answers_crawler.setSleephours(sleephours);
			questions_crawler.setSleephours(sleephours);
		}
		
		Thread answersthd=new Thread(answers_crawler);
		Thread questionsthd=new Thread(questions_crawler);
		Thread commentsthd=new Thread(comments_crawler);
		
		/*two threads */
		answersthd.start();
		questionsthd.start();
		commentsthd.start();
		
	}
}
