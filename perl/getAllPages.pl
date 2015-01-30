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
    my $randint=int(rand(15))%4;
    if($randint==0){
        $ua->proxy('http','http://proxy.pvgl.sap.corp:8080');
    }
    elsif($randint==1){
        $ua->proxy('http','http://proxy.pal.sap.corp:8080');
    }
    elsif($randint==2){
        $ua->proxy('http','http://proxy.pek.sap.corp:8080');
    }
    else{
        $ua->proxy('http','http://proxy.sin.sap.corp:8080');
    }
    mylog($logn,"INFO","use proxy $randint");
    my $res;
    eval{
	 $res=$ua->request(HTTP::Request->new('GET',$url));
    };
    if($@){
	mylog("getpages.log","ERROR",$url."\t".$@);
	return "";
    }
    if(defined $res and $res->is_success){
	mylog($logn,"INFO","get url $url success!");
	#$content=$res->content;
	$content=$res->decoded_content;
	#$content=encode("utf-8",decode("gb2312",$content));
    }else{
	mylog("getpages.log","ERROR","get url $url failed!");
	$content="";
    }
    return $content; 
}

sub getPosts{
    my $url=$_[0];
    my $carsno=$_[1];
    mylog($logn,"INFO","start get forum $url");
    my $data=getURLContent($url);
    if(!$data){
     open(OUT,">>carspages.txt");
     print OUT "$carsno\t0\n";
     close(OUT);
     return;
    }
    my $tree=new HTML::TreeBuilder::XPath;
    $tree->parse($data);
    $tree->eof;

    my $totalPage=0;
    ##parse the data;
    #get total page###;
     my $items=$tree->findnodes('//div[@class="pagearea"]/span');
     my $node=$items->get_node(1);
     if(defined $node){
	$totalPage=$node->as_text();
     }
     else{
     }
     if($totalPage=~/([\d\.]+)/){
 	$totalPage=$1;
     }    
     #print($totalPage);
     open(OUT,">>carspages.txt");
     print OUT "$carsno\t$totalPage\n";
     close(OUT);
     mylog($logn,"INFO","end get forum $url");
}

#getPosts("http://club.autohome.com.cn/bbs/forum-c-2051-1.html");

sub handlelist{
    my $inputfn=$_[0];
    open(IN,$inputfn)||die "can not open $inputfn";
    my $baseurl="http://club.autohome.com.cn/bbs/forum-c-";
    while(<IN>){
	chomp;
	my $no=$_;
	my $url=$baseurl.$no."-1.html";
	print("handling car seriz ".$no."\t".$url."\n");
	getPosts($url,$no);
    }
    close(IN);
}

handlelist("carsno.txt");

