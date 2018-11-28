#!/usr/bin/perl

$iter=0;
$min=0; $max=0;
%count=();

$matchFile=$ARGV[0];
open(my $matchHandle, $matchFile) || die "Could not open $matchFile.\n";
while (<$matchHandle>) {
    my @matches = split(" ", $_);
    my $read = shift @matches;
    my $nbmatch=scalar(@matches);
    $count{$nbmatch}++;


    if($iter==0) {
	$min=$nbmatch;
	$max=$nbmatch;
    }
    else {
	if($nbmatch<$min) {
	    $min=$nbmatch;
	}
	if($nbmatch>$max) {
	    $max=$nbmatch;
	}	
    }
    $iter++;
}
close($matchHandle);
print "$min (".$count{$min}.") >> $max (".$count{$max}.")\n";





