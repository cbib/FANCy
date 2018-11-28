#! /usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Newick;
use Taxonomies;


my $taxType;
my $taxFile;
my $outFile;
my $outFormat = "binary";
my $contract = 1;
my $keepRanks;
my %ranks2keep;
my $listRanks;
my $keepLeaves = 0;
my $restrictFile;
my $help = 0;

my @classes = map {Taxonomies::getTaxonomyClass($_)} Taxonomies::getAllTypes();

my $noArgs = !@ARGV;

my $getter = GetOptions ("taxonomy-type=s" => \$taxType,    
			 "taxonomy=s"   => \$taxFile,   
			 "output=s"  => \$outFile,
                         "output-format=s" => \$outFormat,
                         "contract!" => \$contract,
			 "keep-ranks=s" => \$keepRanks,
			 "list-ranks=s" => \$listRanks,
			 "keep-leaves!" => \$keepLeaves,
			 "restrict=s" => \$restrictFile,
			 "help" => \$help);

checkParameters();

# Construct taxonomy object
my $class = Taxonomies::getTaxonomyClass($taxType);
print "Treating ", $class, " file \n"; 
my $taxonomy = $class->new($taxFile);

# Restrict option
if ($restrictFile) {
    print "Restricting the taxonomy\n";
    open(my $fh, "<", $restrictFile) || die "Could not open $restrictFile: $!";
    my @listIds = <$fh>;
    chomp(@listIds);
    close($fh);
    $taxonomy = $taxonomy->restrict(\@listIds);
    exit(1) if (!defined($taxonomy)); 
}

# Contract option 
if ($contract) {
    print "Contracting the taxonomy\n";
    my %args;
    $args{'ranks2keep'} = \%ranks2keep if (keys(%ranks2keep));
    $args{'keepLeaves'} = $keepLeaves;
    $taxonomy = $taxonomy->contract(%args);
}

# Store object
if ( lc($outFormat) eq "binary") {
    $taxonomy->serialize($outFile);
}
else {
    Newick::toNewick($taxonomy, $outFile);
}

print "Completed ! \n";



########## functions ############


sub checkParameters {
    exit(1) if (!$getter);

    usage() if ($help || $noArgs);

    if ($listRanks) {
	if (Taxonomies::isValidType($listRanks)) {
	    my $class = Taxonomies::getTaxonomyClass($listRanks);
	    print join("\n", @{$class->ranksDocumentation()}), "\n";
	    exit(0);
	}
	else {
	    print STDERR "Unknown taxonomy type '$listRanks'. Possible types: ",
	    join(", ", Taxonomies::getAllTypes()), "\n";
	    exit(1);
	}
    }

    # Test mandatory parameters
    my %mandatory = ("taxonomy-type" => $taxType,
		     "taxonomy" => $taxFile,
		     "output" => $outFile);

    while ( (my $parName, my $parVal) = each(%mandatory) ) {
	if (!$parVal) {
	    print STDERR "$parName parameter is mandatory\n";
	    exit(1);
	}
    }

    # Test taxonomy type
    if (!Taxonomies::isValidType($taxType)) {
	print STDERR "Unknown taxonomy type '$taxType'. Possible types: ",
	join(", ", @classes), ".\n";
	exit(1);
    }

    # Specific options for newick taxonomy
    if (lc($taxType) eq 'newick' && $contract && !$keepRanks) {
	print STDERR "Default 'contract' is not supported for newick taxonomies. Use 'keep-ranks' to specify which ranks to keep.\n";
	exit(1);
    }

    # Test output format
    if ( ! ( lc($outFormat) ~~ ["binary", "newick"] ) ) {
	print STDERR "'output-format' should be 'binary' or 'newick'.\n";
	exit(1);
    }

    # Test ranks to keep
    if ($keepRanks) {
	my $class = Taxonomies::getTaxonomyClass($taxType);
	for my $r (split(",", $keepRanks)) {
	    my $rank = $class->parseRank($r);
	    if (defined($rank)) {
		$ranks2keep{$rank} = 1;
	    }
	    else {
		print STDERR "$r is not a valid rank for taxonomies of type $class\n";
		exit(1);
	    }
	}
    }
}


sub usage {
    my @lines;

    title("USAGE");

    print bold("perl contract.pl"), " --taxonomy-type <taxonomy_type> --taxonomy <file_name> --output <file_name> [OPTIONS]\n";
    print "\nPreprocess a taxonomy to use it with " . bold("tango.pl") . ". <taxonomy_type> can be: "
	. join(", ", @classes) . ".\n\n";


    title("MANDATORY ARGUMENTS");

    argument("taxonomy-type",
    	     " <taxonomy_type>: type of the taxonomy to preprocess.");

    @lines = flatten( map {$_->taxonomyFileName()} @classes);
    argument("taxonomy", " <file_name>: file with the taxonomy to preprocess:\n\t" . join("\n\t", @lines));

    argument("output", " <file_name>: where to save the preprocessed taxonomy.");


    title("OPTIONAL ARGUMENTS");
    
    argument("help",
    	     ": Print this message and exit.");

    argument("output-format", " <format>: binary (default) or newick.");
    
    argument("contract",
     	     " (default) / " . bold("--no-contract")
	     . ": contract the taxonomy.");

    argument("keep-ranks",
	     ": Comma-separated list of ranks to keep when contracting (either its name or an integer).\n"
	     . "\tUse " . bold("--list-ranks") . " to see the ranks available for each taxonomy type.\n"
	     . "\tIf no explicit list of ranks is given, the contraction will keep the canonical ranks.");

    argument("list-ranks", " <taxonomy_type>: list the ranks available for a taxonomy type.");

    argument("keep-leaves", ": always keep the leaves when contracting, independently of their rank.");

    argument("restrict", " <file_name>: restrict the taxonomy to the set of nodes in <file_name> (one per line).");

    exit();
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

sub flatten {
    map @$_, @_;
}
