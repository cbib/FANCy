#! /usr/bin/env perl
use Getopt::Long;
use Storable;
use strict;
use warnings;

my $matchFile;
my $mapFile;
my $outFileName;

my $getter = GetOptions ("matches=s" => \$matchFile,    
			 "mapping=s"   => \$mapFile,   
			 "output=s"  => \$outFileName); 

# Test mandatory parameters
my @all_params=($matchFile,$mapFile,$outFileName);
foreach my $param (@all_params) {
    if(!$param || $param eq "") {
	&usage();
    }
}

# Open output file to write
my $outHandle = *STDOUT;
open($outHandle, '>', $outFileName) || die "Could not open $outFileName.\n";


# Get stored map file
my $map = retrieve($mapFile);


# Read match file
open(my $matchHandle, $matchFile) || die "Could not open $matchFile.\n";
while (<$matchHandle>) {
    my @matches = split(" ", $_);
    my @convertedMatches = (shift @matches);
    my %converted = ();
    while (@matches) {
        my $m = shift @matches;
        if (defined $map->{$m}) {
            $converted{$map->{$m}}++;
        }
    }
    push(@convertedMatches, keys %converted);
    print $outHandle "@convertedMatches\n";
}
close($matchHandle);

close($outHandle);





######### functions ############

sub usage {
    print "Usage: perl relabel.pl --matches <matches_file> --mapping <mapping_file> [--output <output_file>]\n";
    print "\t<matches_file>: Format: 'ReadID LeafID [LeafID...]'. E.g.: read1 S000367885 S000406428 S000438419\n";
    print "\t<mapping_file>: output of equalize.pl.\n";
    print "\t<output_file>: destination of the conversion. Default: STDOUT.\n";
    exit;
}
