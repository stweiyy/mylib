#!/usr/bin/perl
use warnings;
use utf8;
use strict;
binmode(STDIN,':encoding(utf8)');
binmode(STDOUT,':encoding(utf8)');
binmode(STDERR,':encoding(utf8)');

use threads;
use threads::shared;
use LWP::UserAgent;
use Encode;
use LWP::Simple;
use HTML::TreeBuilder::XPath;
use Data::Dumper;
use File::Copy qw(copy);

#########Simple Log Function############################
sub mylog{
    my ($fn,$type,$msg,$tid)=@_;
    my $filename="$tid-$fn";
    my $logmsg=localtime()."\t".$type."\t".$msg."\n";
    open(OUT,">>$filename");
    print OUT $logmsg;
    close(OUT);
}
my $logn="event.log";
#mylog($logn,"info","hello");
#########################################################

opendir(DIR,".") or die "can not open dir!";
my @dir =readdir DIR;
foreach my $file(@dir){
    if($file=~/(\d+)\.html/){
	my $carsno=$1;
	open(IN,"$file") or return;
	binmode(IN,':utf8');
	my $data=join("",<IN>);
	close(IN);
	if($data=~/var\s*config\s*=\s*(.+);/){
	    open(OUT,">json/$carsno-config.json");
	    binmode(OUT,':encoding(utf8)');
	    print OUT $1;
	    close(OUT);
	    # print($1);
	}
	if($data=~/var\s*option\s*=\s*(.+);/){
	    open(OUT,">json/$carsno-option.json");
	    binmode(OUT,':encoding(utf8)');
	    print OUT $1;
	    close(OUT);
	}
    }
}

