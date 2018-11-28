#!/usr/bin/perl


$max=10; $itermax=0;
$min=1;  $itermin=0;
$number=10000;

open(WMIN,">MIN.match");
open(WMAX,">MAX.match");
$matchFile=$ARGV[0];
open(my $matchHandle, $matchFile) || die "Could not open $matchFile.\n";
while (<$matchHandle>) {
    @matches = split(" ", $_);
    $read = shift @matches;
    $nbmatch=scalar(@matches);
   
    if($nbmatch==$min ) {
	if($itermin<$number) {
	    print WMIN $_;
	}
	$itermin++;
    }
    
    if($nbmatch==$max ) {
	if($itermax<$number) {
	    print WMAX $_;
	}
	$itermax++;
    }
}
close($matchHandle);
close(WMIN);
close(WMAX);



