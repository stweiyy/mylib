#!/usr/bin/perl
use warnings;
use utf8;
#binmode(STDIN,':encoding(utf8)');
#binmode(STDOUT,':encoding(utf8)');
#binmode(STDERR,':encoding(utf8)');

use threads;
use threads::shared;
use LWP::UserAgent;
use Encode;
use LWP::Simple;
use HTML::TreeBuilder::XPath;
use Data::Dumper;

#########Simple Log Function############################
sub mylog{
    my ($fn,$type,$msg)=@_;
    my $logmsg=localtime()."\t".$type."\t".$msg."\n";
    open(OUT,">>$fn");
    print OUT $logmsg;
    close(OUT);
}
sub mylog2{
    my ($fn,$type,$msg,$thdid)=@_;
    my $logfn="log/$thdid-$fn";
    my $logmsg=localtime()."\t".$type."\t".$msg."\n";
    open(OUT,">>$logfn");
    print OUT $logmsg;
    close(OUT);
}
my $logn="event.log";
#mylog($logn,"info","hello");
#########################################################

#######Get URL content##################################
sub getURLContent{

    my $url=$_[0];
    my $thdid=$_[1];

    my $content="";
    my $ua=LWP::UserAgent->new();
    my $randint=int(rand(19))%5;
    $ua->proxy('http','http://proxy.sha.sap.corp:8080');
    if($randint==0){
    #    $ua->proxy('http','http://proxy.pvgl.sap.corp:8080');
    }
    elsif($randint==1){
     #   $ua->proxy('http','http://proxy.pal.sap.corp:8080');
    }
    elsif($randint==2){
      #  $ua->proxy('http','http://proxy.pek.sap.corp:8080');
    }
    elsif($randint==3){
       # $ua->proxy('http','http://proxy.sin.sap.corp:8080');
    }
    else{
        #$ua->proxy('http','http://proxy.sha.sap.corp:8080');
    }
    my $res=$ua->request(HTTP::Request->new('GET',$url));
    if(defined $res and $res->is_success){
        mylog2("url.log","INFO","proxy $randint\tget url $url success!",$thdid);
        #$content=$res->decoded_content;
        #$content=encode("utf-8",decode("gb2312",$content));
        $content=$res->decoded_content;
	return $content;
    }
    else{
       my $resmsg=$res->status_line;
       mylog("log/failed.log","ERROR","$url\t$resmsg");
       return("");
    } 
}
###get the posts for one page of the forum, success return 1 ,else return -1
sub getPostsList{
    my $url=$_[0];
    my $carsno=$_[1];
    my $thdid=$_[2];

    my $data=getURLContent($url,$thdid);
    if(!$data){
	mylog("log/emptypage.log","ERROR","the content of $url is empty");
	return -1;
    }
    my $tree=new HTML::TreeBuilder::XPath;
    $tree->parse($data);
    $tree->eof;

     #get the year of the data page
     my $dateitems=$tree->findnodes('//dl[@class="list_dl "]/dd/span[@class="tdate"]');
     my $dateitem=$dateitems->get_node(1);
     my $datayear=2015;
     if(defined $dateitem){
	 my $datestr=$dateitem->as_text();
	 if($datestr=~/(\d+)-/){
	    $datayear=$1;
	 }
     }
     #year control ########################################################
     if($datayear<2012){
	 return(-1);
     }

     my $pageurl="";
     my $items=$tree->findnodes('//dl[@class="list_dl "]/dt/a');

     for my $link($items->get_nodelist()){
	 if(defined $link and ref $link){
	    my $pageurl=$link->attr("href");
	    if($pageurl=~/thread-o/){
		next;
	    }
	    $pageurl="http://club.autohome.com.cn".$pageurl;
	    my $pagedata=getURLContent($pageurl,$thdid);
	    if(!$pagedata){
		mylog("log/emptypage.log","ERROR","the content of posts $pageurl is empty");
		next;
	    }
	    my $pagetree=new HTML::TreeBuilder::XPath;
	    $pagetree->parse($pagedata);
	    $pagetree->eof;

	   my $pagetotal=0;
	   my $subitems=$pagetree->findnodes('//span[@class="gopage"]');
           my $subnode=$subitems->get_node(1);
           if(defined $subnode){
	      $pagetotal=$subnode->as_text();
           }

           if($pagetotal=~/([\d]+)/){
		$pagetotal=$1;
           }         
            my $subbaseurl="";
	    if($pageurl=~/(.+)-\d+.html$/){
		$subbaseurl=$1;
	    }
	    for(my $i=1;$i<=$pagetotal;$i++){
		my $posturl=$subbaseurl."-".$i.".html";
		my $postdata=getURLContent($posturl,$thdid);
		
		my $postfn="";
		if($posturl=~/(thread.*html)$/){
		    $postfn=$1;
		}
		if($postdata){
		    open(OUT,">posts/$carsno/$postfn") or next;
		    binmode(OUT,":utf8");
		    print OUT $postdata;
		    close(OUT);
		}
	    }
	 }
  }
  return 1;
}

#getPostsList("http://club.autohome.com.cn/bbs/forum-c-801-2.html",801,1);

sub getForums{
    my $url=$_[0];
    my $carsno=$_[1];
    my $no=$carsno;
    my $totalpage=$_[2];
    my $tid=$_[3];

    if($totalpage<1){
	return;
    }
    if(not -e "posts/$no"){
	mkdir("posts/$no");
    }

    my $msg="thread $tid:handling car seriz ".$no."\t".$url."\ttotal page ".$totalpage;
    mylog("log/forum.log","INFO",$msg);

    my $startpage=1;

    if(-e "posts/$no/record.txt"){
	open(INR,"posts/$no/record.txt");
	my $line=<INR>;
	chomp($line);
	$startpage=$line;
	$startpage=$startpage+1;
	close(INR);
    }
    my $baseurl="http://club.autohome.com.cn/bbs/forum-c-";

    mylog("log/forum.log","INFO","thread $tid:cars seriz $carsno,start at page $startpage");

    for(my $i=$startpage;$i<=$totalpage;$i++){
         ###page control##################################################
	 if($i>100){
	     last;
	 }
         my $pageurl=$baseurl.$carsno."-".$i.".html";
         my $status=getPostsList($pageurl,$carsno,$tid);
	 if($status>0){
	     open(OUT,">posts/$no/record.txt");
	     print OUT $i;
	     close(OUT);
	 }
    }
    mylog("log/forum.log","INFO","thread $tid:end get $carsno forum $url");
    open(FIN,">>log/finished.txt") or die "can not open finished.txt";
    print FIN $carsno."\tfinished by thread $tid\n";
    close(FIN);
}

#getPosts("http://club.autohome.com.cn/bbs/forum-c-2051-1.html");

my $filename="carspages_sort.txt";
my %cars_pages=();
open(IN,$filename) ||die "can not open $filename\n";
while(<IN>){
    chomp;
    my $line=$_;
    my @segs=split(/\s+/,$line);

    my $no=$segs[0];
    my $pagecount=$segs[1];
    $cars_pages{$no}=$pagecount;
}
close(IN);
#print Dumper(\%cars_pages);

sub threadEntry{
    my ($tid,$totalThread,%cars_pages)=@_;
    my $baseurl="http://club.autohome.com.cn/bbs/forum-c-";
    #print("thread id $tid\n");
    foreach my $key(keys %cars_pages){
	#print("$key : $cars_pages{$key}\n");
	my $carsno=$key;
	my $carstotalpage=$cars_pages{$key};

	if(($carsno % $totalThread) == $tid){
	    my $url=$baseurl.$carsno."-1.html";
	    my $statusinfo="thread ID $tid :handling car seriz ".$carsno."\t".$url."\ttotal page ".$carstotalpage;
	    mylog("log/status.log","INFO",$statusinfo);
	    getForums($url,$carsno,$carstotalpage,$tid);
	}
    }
}

my $thdCount=50;
my @thdlist=();
for(my $i=0;$i<$thdCount;$i++){
    my $thdid=threads->new(\&threadEntry,$i,$thdCount,%cars_pages);
    push(@thdlist,$thdid);
}
foreach my $thditem(@thdlist){
    $thditem->join;
}

