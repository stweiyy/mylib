#!/usr/bin/perl
use warnings;
use utf8;
use strict;
binmode(STDIN,':encoding(utf8)');
binmode(STDOUT,':encoding(utf8)');
binmode(STDERR,':encoding(utf8)');

my @files=("a.txt","a0.txt","a00.txt","b.txt","c.txt","d.txt","mb.txt","mpv.txt","p.txt","qk.txt","s.txt","suv.txt");
my %mapinfo=("a.txt"=>"紧凑型车","a0.txt"=>"小型车","a00.txt"=>"微型车","b.txt"=>"中型车","c.txt"=>"大型车","d.txt"=>"豪华车","mb.txt"=>"微面","mpv.txt"=>"MPV","p.txt"=>"皮卡","qk.txt"=>"轻客","s.txt"=>"跑车","suv.txt"=>"SUV");

my %carsSeriz=();
foreach my $file(@files){
    open(IN,$file) or die "can not open $file\n";
    binmode(IN,':encoding(utf8)');
    while(<IN>){
	chomp;
	my $line=$_;
	my @segs=split(/:/,$line);
	my $url=$segs[2];
	my $carsno=0;
	if($url=~/(\d+)/){
	    $carsno=$1;
	}

	$carsSeriz{$carsno}=$mapinfo{$file};
#	print($carsno."\t".$mapinfo{$file}."\n");
    }
    close(IN);
}


open(IN,"carsinfo.csv") or die "can not open file\n";
binmode(IN,':encoding(utf8)');
while(<IN>){
    my $line=$_;
    my $type="";
    my $no=0;
    if($line=~/^(\d+)/){
	$no=$1;
    }
    $type=$carsSeriz{$no};
    my $newline=$type.",".$line;
    print($newline);
}
close(IN);
