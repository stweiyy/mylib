#!/usr/bin/perl
use warnings;
use utf8;
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
sub getBasicInfo{
    my $url=$_[0];
    my $urlname=$_[1];
    #$url="http://www.autohome.com.cn/3085/";
    #$url="http://www.autohome.com.cn/155/";
    my $data=getURLContent($url);
    my $tree=new HTML::TreeBuilder::XPath;
    $tree->parse($data);
    $tree->eof;
    ######data field###################
    my $newmax="";
    my $newmin="";
    my $speedbox="";
    my $bodystruc="";

    my $userscore="";
    my $rankpos="";

    my $spacescore="";
    my $spacescorerank="";
    my $powerscore="";
    my $powerscorerank="";
    my $operatescore="";
    my $operatescorerank="";
    my $oilscore="";
    my $oilscorerank="";
    my $comfortscore="";
    my $comfortscorerank="";
    my $facescore="";
    my $facescorerank="";
    my $innerscore="";
    my $innerscorerank="";
    my $pfratio="";
    my $pfratiorank="";

    my $imgurl="";
    
    #get new car price###
    my $items=$tree->findnodes('//dl[@class="autoseries-info"]//a[@class="red"]');
    my $pricenode=$items->get_node(1);
    my $priceinfo="";
    if(defined $pricenode) {
	$priceinfo=$pricenode->as_text();
    }
    if($priceinfo=~/([\d\.]+)-([\d\.]+)/){
	$newmin=$1;
	$newmax=$2;
    }
    elsif($priceinfo=~/([\d\.]+)/){
	$newmin=$1;
    }
 #   print($newmin."\n".$newmax."\n");
    $items=$tree->findnodes('//dl[@class="autoseries-info"]/dd');
    my $sb=$items->get_node(3);
    my $bodypos=$sb->find_by_tag_name("span");
    my @speedboxitems=$bodypos->left();
    for my $li(@speedboxitems){
	if(ref $li){
	    $speedbox=$speedbox.($li->as_text)."\t";
	}
    }
    $speedbox=~s/\s*$//g;
  #  print $speedbox;
    my @bodystrucitems=$bodypos->right();
    for my $li(@bodystrucitems){
	if(ref $li){
	    $bodystruc=$bodystruc.($li->as_text)."\t";
	}
    }
    $bodystruc=~s/\s*//g;
  #  print($bodystruc."\n");
    #get image url
    $items=$tree->findnodes('//div[@class="autoseries"]/div/div[@class="autoseries-pic-img1"]/a/img');
    $imgurl=$items->get_node(1)->attr("src");

    #get user score
    $items=$tree->findnodes('//div[@class="koubei"]/div/a[@class="font-score"]');
    if(defined $items->get_node(1)){
	$userscore=$items->get_node(1)->as_text();
    }
 #   print($userscore);

    #get rank value
    $items=$tree->findnodes('//div[@class="koubei-brand"]/h4/a');
    if(defined $items->get_node(1)){
	$rankpos=$items->get_node(1)->as_text;
    }


    $items=$tree->findnodes('//div[@class="koubei-con-rank"]/table/tr/td');
    #get space score and rank
    my @allnodes=$items->get_nodelist();
    if(defined($items) and scalar(@allnodes)==16){

	$spacenode=$items->get_node(1)->as_text;
	if($spacenode=~/([\d\.]+)/){
	    $spacescore=$1;
	}
	$spacenode=$items->get_node(2)->as_text;

	if($spacenode=~/([\d\.]+)/){
	    $spacescorerank=$1;
	}
	my $tdnode=$items->get_node(3)->as_text;
	if($tdnode=~/([\d\.]+)/){
	    $powerscore=$1;    
	}
	$tdnode=$items->get_node(4)->as_text;
	if($tdnode=~/([\d\.]+)/){
	    $powerscorerank=$1;
	}
	$tdnode=$items->get_node(5)->as_text;
	if($tdnode=~/([\d\.]+)/){
	    $operatescore=$1;
	}
	$tdnode=$items->get_node(6)->as_text;
	if($tdnode=~/([\d\.]+)/){
	    $operatescorerank=$1;
	}
	$tdnode=$items->get_node(7)->as_text;
	if($tdnode=~/([\d\.]+)/){
	    $oilscore=$1;
	}
	$tdnode=$items->get_node(8)->as_text;
	if($tdnode=~/([\d\.]+)/){
	    $oilscorerank=$1;
	}
	$tdnode=$items->get_node(9)->as_text;
	if($tdnode=~/([\d\.]+)/){
	    $comfortscore=$1;
	}
	$tdnode=$items->get_node(10)->as_text;
	if($tdnode=~/([\d\.]+)/){
	    $comfortscorerank=$1;
	}
	$tdnode=$items->get_node(11)->as_text;
	if($tdnode=~/([\d\.]+)/){
	    $facescore=$1;
	}
	$tdnode=$items->get_node(12)->as_text;
	if($tdnode=~/([\d\.]+)/){
	    $facescorerank=$1;
	}
	$tdnode=$items->get_node(13)->as_text;
	if($tdnode=~/([\d\.]+)/){
	    $innerscore=$1;
	}
	$tdnode=$items->get_node(14)->as_text;
	if($tdnode=~/([\d\.]+)/){
	    $innerscorerank=$1;
	}
	$tdnode=$items->get_node(15)->as_text;
	if($tdnode=~/([\d\.]+)/){
	    $pfratio=$1;
	}
	$tdnode=$items->get_node(16)->as_text;
	if($tdnode=~/([\d\.]+)/){
	    $pfratiorank=$1;
	}

    }
    open(MYOUT,">>newcars.csv");

    print MYOUT ($urlname.",".$url.",".$newmin.",",$newmax.",".$speedbox.",".$bodystruc.",".$userscore.",".$rankpos.",".$spacescore.",".$spacescorerank.",".$powerscore.",".$powerscorerank.",".$operatescore.",".$operatescorerank.",".$oilscore.",".$oilscorerank.",".$comfortscore.",".$comfortscorerank.",".$facescore.",".$facescorerank.",".$innerscore.",".$innerscorerank.",".$pfratio.",".$pfratiorank.",".$imgurl."\n");
    close(MYOUT);
 #   print("\nall nodes count\n".scalar(@allnodes)."\n");
  #  print("\n\n\n");
   # for my $link($items->get_nodelist()){
	#print($link);
#	if(ref $link){
#	    print($link->as_text);
#	}
	#if(ref($speedboxitem) eq "SCALAR"){
	 #   print($speedboxitem);
	#}
	#print($speedboxitem);
	#print(\$speedboxitem);
 #   }
    #$bodypos->dump;
    #print($bodypos->pos());
    #print($sb->pos($bodypos));
    #print($sb->as_text());
    #for my $link(@content){
#	$link->dump;
   # }
    #$sb->dump;
    #$items=$tree->findnodes('//dt[@id="series_che168"]');
    #for my $item($items->get_nodelist()){
#	 $item->dump;

 #   }
    #print($items->get_node(1)->as_text());
    #for my $item($items->get_nodelist()){
#	print($item->as_text());
 #   }
    

}
#getBasicInfo('he',"name");

#my $inputfn=$ARGV[0];
#if(not defined($inputfn)){
 #   die("you did not supply input file!");
#}
sub handlelist{
    my $inputfn=$_[0];
    open(IN,$inputfn)||die "can not open $inputfn";
    while(<IN>){
	chomp;
	my $line=$_;
	my @segs=split(/:/,$line);
	my $url=$segs[1].":".$segs[2];
	my $name=$segs[0];
	print("handing ".$name."\t".$url."\n");
	getBasicInfo($url,$name);
    }
    close(IN);
}


opendir(DIR,".") or die "can not open dir!";
@dir=readdir DIR;
foreach my $file(@dir){
    if($file=~/.txt$/){
	print($file."\n");
	handlelist($file);
    }
}
closedir(DIR);
