#!/usr/bin/perl
use warnings;
use utf8;
#binmode(STDIN,':encoding(utf8)');
#binmode(STDOUT,':encoding(utf8)');
#binmode(STDERR,':encoding(utf8)');

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
my $logn="event.log";
#mylog($logn,"info","hello");
#########################################################

#######Get URL content##################################
sub getURLContent{
    my $url=$_[0];
    my $content="";
    my $ua=LWP::UserAgent->new();
    $ua->proxy('http','http://proxy.pvgl.sap.corp:8080');

    my $res;
    $res=$ua->request(HTTP::Request->new('GET',$url));
    if(defined $res and $res->is_success){
	mylog($logn,"INFO","get url $url success!");
	#$content=$res->content;
	$content=$res->decoded_content;
	#$content=encode("utf-8",decode("gb2312",$content));
    }else{
	mylog("getconfig.log","ERROR","get url $url failed!");
	$content="";
    }
    return $content; 
}


sub handlelist{
    my $inputfn=$_[0];
    open(IN,$inputfn)||die "can not open $inputfn";
    my $baseurl="http://car.autohome.com.cn/config/series/";
    while(<IN>){
	chomp;
	my $no=$_;
	my $url=$baseurl.$no.".html";
	my $filename=$no.".html";
	if(-e $filename){
	    next;
	}
	my $data=getURLContent($url);
	if(!$data){
	    next;
	}
	open(OUT,">$no.html") or die "can not open";
	binmode(OUT,':encoding(utf8)');
	print OUT $data;
	close(OUT);
    }
    close(IN);
}

handlelist("carsno.txt");

