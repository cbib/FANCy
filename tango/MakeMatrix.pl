#/usr/bin/perl
use Getopt::Long;
use Storable;


my $limit;
my $getter = GetOptions ("limit=i" => \$limit);    


if(!$limit) {
    print "perl $0 --limit <numeric> \n";
    exit;
}




for($qval=0 ; $qval<=1 ; $qval+=0.1) {

    print "- $qval \n";
    my $outfile="MATRIX_".$qval;
    my %mat=();
    
    for($fn=0 ; $fn<=$limit ; $fn++) {
	for($tp=1 ; $tp<=$limit ; $tp++) {
	    for($fp=0 ; $fp<=$limit ; $fp++) {
		$score = $qVal * ($fn / $tp) + (1 - $qVal) * ($fp / $tp);
		$key=$fn."_".$tp."_".$fp;
		$mat{$key}=$score;
	    }
	}
    }
    store(\%mat,$outfile);
}
