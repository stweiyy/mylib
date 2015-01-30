#!/usr/bin/perl
use warnings;
use utf8;
use LWP::UserAgent;
use Encode;
use LWP::Simple;
use HTML::TreeBuilder::XPath;

#########Simple Log Function############################
sub mylog{
    my ($fn,$type,$msg)=@_;
    my $logmsg=localtime()."\t".$type."\t".$msg."\n";
    open(OUT,">>$fn");
    print OUT $logmsg;
    close(OUT);
}
my $logn="event.log";
#mylog($logn,"info","hello");
#########################################################

#######Get URL content##################################
sub getURLContent{
    my $url=$_[0];
    my $content="";
    my $ua=LWP::UserAgent->new();
    $ua->proxy('http','http://proxy.pvgl.sap.corp:8080');
    my $res=$ua->request(HTTP::Request->new('GET',$url));
    if($res->is_success){
	mylog($logn,"INFO","get url $url success!");
	$content=$res->content;
	$content=encode("utf-8",decode("gb2312",$content));
    }else{
	mylog($logn,"ERROR","get url $url failed!");
	$content="";
    }
    return $content; 
}

sub getCarSeriz{
    my $url=$_[0];
    my $type=$_[1];
    my $typename=$type.".txt";
    #my $url="http://www.autohome.com.cn/a00/";
    my $data=getURLContent($url);
    my $tree=new HTML::TreeBuilder::XPath;
    $tree->parse($data);
    $tree->eof;
    #my $items=$tree->findnodes('//ul[@class="rank-list-ul"]');
    open(OUT,">$typename");
    my $items=$tree->findnodes('//h4//a');
    my %hash=();
    for my $item($items->get_nodelist()){
	 #$item->dump;
	my $urladdr=$item->attr("href");
	my $classinfo=$item->attr("class");
	my $textinfo=$item->as_text();
	if(defined($classinfo) and $classinfo eq "greylink"){
		next;
	}
	if($urladdr=~/http:\/\/www.autohome.com.cn\/(\d+)\//){
	    if(exists($hash{$1})){
		next;
	    }
	    else{
		$hash{$1}=1;
		$urladdr="http://www.autohome.com.cn/".$1."/";
		print OUT ($textinfo.":".$urladdr."\n");
	    }
	}
    }   
    close(OUT);
}

getCarSeriz("http://www.autohome.com.cn/a00/","a00");
getCarSeriz("http://www.autohome.com.cn/a0/","a0");
getCarSeriz("http://www.autohome.com.cn/a/","a");
getCarSeriz("http://www.autohome.com.cn/b/","b");
getCarSeriz("http://www.autohome.com.cn/c/","c");
getCarSeriz("http://www.autohome.com.cn/d/","d");
getCarSeriz("http://www.autohome.com.cn/suv/","suv");
getCarSeriz("http://www.autohome.com.cn/mpv/","mpv");
getCarSeriz("http://www.autohome.com.cn/s/","s");
getCarSeriz("http://www.autohome.com.cn/p/","p");
getCarSeriz("http://www.autohome.com.cn/mb/","mb");
getCarSeriz("http://www.autohome.com.cn/qk/","qk");
