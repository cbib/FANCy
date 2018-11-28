#! /usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Scalar::Util;
use Storable;
use TaxoAssignment;


my $taxFile;
my $matchFile;
my $q_parameter = 0.5;
my $outFileName;
my $seed;
my $help = 0;

my $noArgs = !@ARGV;

my $getter = GetOptions ("taxonomy=s" => \$taxFile,
			 "matches=s"   => \$matchFile,
			 "output=s"  => \$outFileName,
			 "q-value=s"  => \$q_parameter,
			 "seed=i" => \$seed,
			 "help" => \$help);

checkParameters();


# The q parameter format
my @Qvalues=();
if(defined($q_parameter)) { # Must test with defined, 0 is a legitimate value
    if($q_parameter eq "all") {
	for(my $i=0 ; $i<=1 ; $i+=0.1) {
	    push(@Qvalues,$i);
	}
    }
    else {
	push(@Qvalues,$q_parameter);
    }
}


# Get taxonomy file
my $taxonomy = Taxonomy::deserialize($taxFile);


foreach my $qval (@Qvalues) {

    print "-> $qval \n";
    
    # get matrix
    my $MatrixFile="MATRIX_".$qval;
    my $mat;
    if (-e $MatrixFile) {
	$mat = retrieve($MatrixFile);
    }
    else {
	$mat = {};
    }
    
    my $outHandle;
    open($outHandle, '>',$outFileName."_".$qval) || die "Could not open ${outFileName}_$qval.\n";
    my $value;
    my $assignments;
    open(my $matchHandle, $matchFile) || die "Could not open $matchFile.\n";
    while (<$matchHandle>) {
	my @matches = split(" ", $_);
	my $read = shift @matches;
	#print "*** $read ***\n";
	(my $contractedMatches, my $missing) = $taxonomy->toContracted(\@matches);
	if (!@{$contractedMatches}) {
	    print STDERR "No valid identifiers present for read $read.\n"; 
	}
	else {
	    if (@{$missing}) {
		print STDERR "Identifiers not present in the taxonomy (for read $read): ",
		join(", ", @{$missing}), "\n";
	    }
	    
	    if ( @{$contractedMatches} > 1) { 
		($value, $assignments) = TaxoAssignment::assign($taxonomy, $qval, $read, $contractedMatches,\%{$mat});
		if (@{$assignments}) {
		    TaxoAssignment::printResult($taxonomy, $read, $value, $assignments, $outHandle);
		}
	    }
	    else {
		TaxoAssignment::printResultSingle($taxonomy, $read, $contractedMatches->[0], $outHandle);
	    } 
	}
    }
    close($matchHandle);
    close($outHandle);
}




########## functions ############

sub checkParameters {
    exit(1) if (!$getter);

    usage() if ($help || $noArgs);

    # Test mandatory parameters
    my %mandatory = ("taxonomy" => $taxFile,
		     "matches" => $matchFile,
		     "output" => $outFileName);

    while ( (my $parName, my $parVal) = each(%mandatory) ) {
	if (!$parVal) {
	    print STDERR "$parName parameter is mandatory\n";
	    exit(1);
	}
    }
    
    if ($q_parameter ne "all" && (
	    !Scalar::Util::looks_like_number($q_parameter) ||
	    $q_parameter < 0 || $q_parameter > 1)
	) {
	print STDERR "q-value must be either 'all' or a number between 0 and 1.\n";
	exit(1);
    }

    if (defined($seed)) {
	srand($seed);
    }
}

sub usage {
    title("USAGE");
    
    print bold("perl tango.pl"), " --taxonomy <preprocessed_taxonomy> --matches <file_name> --output <file_name> [OPTIONS]\n";
    print "\nTaxonomic assignment of metagenomic reads.\n\n";

    title("MANDATORY ARGUMENTS");

    argument("taxonomy",
	     " <file_name>: output of " . bold("contract.pl") . ".");

    argument("matches",
	     " <file_name>: File with the matches, with the format 'ReadID NodeID [NodeID...]'.\n"
	     . "\tE.g.: 'read1 S000367885 S000406428 S000438419'.");

    argument("output",
	     " <file_name>: where to save the assignment. The " . bold("q-value")
	     . " will be appended at the end of the file name.\n"
	     . "\tE.g.: if " . bold("output") . " is 'assignments' and no "
	     . bold("q-value") . " was given, the output will be saved in 'assignments_0.5'.");

    title("OPTIONAL ARGUMENTS");

    argument("help",
	     ": Print this message and exit.");

    argument("q-value",
	     ": either 'all' (the assignment will be computed for values 0, 0.1, 0.2, ..., 1) or a number between 0 and 1.\n"
             . "\t0 will assign to leaves, 1 to LCA. Default: 0.5.");

    argument("seed",
	     " <integer>: Seed for the (pseudo) random number generator. When there is more than one optimal node for a read\n"
	     . "\twe choose one at random. If repeatability is important, use the same seed for diferent tango executions.");

    exit(0);
}

sub bold {
    my $text = shift;
    return "\e[1m$text\e[0m";
}

sub title {
    my $text = shift;
    print bold("$text\n\n");
}

sub argument {
    my ($name, $text) = @_;
    print bold("--$name"), "$text\n\n";
}
