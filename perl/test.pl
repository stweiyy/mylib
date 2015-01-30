use warnings;
use threads;
use threads::shared;

sub count{
    my ($start,$end)=@_;
    my $total=0;
    for(my $i=$start;$i<$end;$i++){
	$total+=$i;
    }
    return $total;
}

my $startTime=time();
my ($max)=@ARGV;

my $part=$max/4;

my $thr0=threads->new(\&count,1,$part);
my $thr1=threads->new(\&count,$part,2*$part);
my $thr2=threads->new(\&count,2*$part,3*$part);
my $thr3=threads->new(\&count,3*$part,$max);


my $total1=$thr0->join;
my $total2=$thr1->join;
my $total3=$thr2->join;
my $total4=$thr3->join;

my $total=$total1+$total2+$total3+$total4;
print "total:".$total."\n";
my $endTime=time();

print "time total:".($endTime-$startTime)."\n";
