#! /usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Storable;
use Taxonomy;
use Taxonomies;

my $sourceFile;
my $targetFile;
my $mappingFile;
my $outputFile;
my $help = 0;

my $noArgs = !@ARGV;

my $getter = GetOptions("source-taxonomy=s" => \$sourceFile,
			"target-taxonomy=s" => \$targetFile,
			"mapping=s" => \$mappingFile,
			"output=s" => \$outputFile,
			"help" => \$help);

checkParameters();

my $sourceTaxo = Taxonomy::deserialize($sourceFile);
my $targetTaxo = Taxonomy::deserialize($targetFile);

my $sourceType = ref($sourceTaxo);
my $targetType = ref($targetTaxo);


my %initialTranslation;

if ($sourceTaxo->canMapTo($targetType)) {
    print "Parsing mapping file\n";
    my $nextPair = $sourceTaxo->generatePairs('target' => $targetType, 'mappingFile' => $mappingFile);
    my ($sourceNode, $targetNode) = $nextPair->();
    while (defined $sourceNode) {
	if ($sourceTaxo->toContracted($sourceNode) && $targetTaxo->toContracted($targetNode)) {
	    $initialTranslation{$sourceNode}{$targetNode} = 1;
	}
	($sourceNode, $targetNode) = $nextPair->();
    }
}
elsif ($targetTaxo->canMapTo($sourceType)) {
    print STDERR "Warning: using reverse mapping\n";
    print "Parsing mapping file\n";
    my $nextPair = $targetTaxo->generatePairs('target' => $sourceType, 'mappingFile' => $mappingFile);
    my ($targetNode, $sourceNode) = $nextPair->();
    while (defined $targetNode) {
	if ($sourceTaxo->toContracted($sourceNode) && $targetTaxo->toContracted($targetNode)) {
	    $initialTranslation{$sourceNode}{$targetNode} = 1;
	}
	($targetNode, $sourceNode) = $nextPair->();
    }
}
else {
    print STDERR "No available mapping from $sourceType to $targetType\n";
    exit(1);
}



my $inverted = $sourceTaxo->getInvertedToContracted();

my %translation = ();
my $sortedPreorder = $sourceTaxo->sortPreorder($sourceTaxo->getNodes());

print "Computing correspondence\n";
while (@{$sortedPreorder}) {
    my $sourceNode = pop(@{$sortedPreorder});
    my %translatedSet = ();
    my $allExpanded = $inverted->{$sourceNode};
    while (my $expanded = each %{$allExpanded}) {
	while (my $translated = each %{$initialTranslation{$expanded}}) {
	    my $contracted = $targetTaxo->toContracted($translated);
	    $translatedSet{$contracted} = 1 if (defined $contracted);
	}
    }

    if ( !(keys(%translatedSet)) ) {
	for my $child (@{$sourceTaxo->children($sourceNode)}) {
	    my $translated = $translation{$child};
	    $translatedSet{$translated} = 1 if (defined $translated);
	}
    }

    my @listTranslated = keys(%translatedSet);
    my $lca = $targetTaxo->lcaList(\@listTranslated);
    if (defined $lca) {
	for my $expanded (keys %{$allExpanded}) {
	    $translation{$expanded} = $lca;
	}
    }
}

store(\%translation, $outputFile);


######### functions ##########

sub checkParameters {
    exit(1) if (!$getter);

    usage() if ($help || $noArgs);

    # Test mandatory parameters
    my %mandatory = ("source-taxonomy" => $sourceFile,
		     "target-taxonomy" => $targetFile,
		     "mapping" => $mappingFile,
		     "output" => $outputFile);

    while ( my ($parName, $parVal) = each(%mandatory) ) {
	if (!$parVal) {
	    print STDERR "$parName parameter is mandatory\n";
	    exit(1);
	}
    }
}


sub usage {
    title("USAGE");
    
    print bold("perl equalize.pl"), " --source-taxonomy <file_name> --target-taxonomy <file_name> --mapping <file_name> --output <file_name> [OPTIONS]\n";
    print "\nProduce a correspondence from nodes in source taxonomy to nodes in target taxonomy.\n"
	, "Both taxonomies must be the output of " . bold("contract.pl") . ". If a direct mapping is not available\n"
	, "(e.g. from NCBI to RDP), the inverse of the reverse mapping will be used, if available.\n\n";

    title("MANDATORY ARGUMENTS");
    
    argument("source-taxonomy",
	     " <file_name>: file with the preprocessed source taxonomy.");

    argument("target-taxonomy",
	     " <file_name>: file with the preprocessed target taxonomy.");
    
    my @classes = map {Taxonomies::getTaxonomyClass($_)} Taxonomies::getAllTypes();
    my @lines = flatten( map {$_->equalizeDocumentation() } @classes);
    argument("mapping",
	     " <file_name>: file with the initial mapping:\n\t" . join("\n\t", @lines));

    argument("output",
	     " <file_name>: where to save the correspondence.");

    title("OPTIONAL ARGUMENTS");
    
    argument("help",
    	     ": Print this message and exit.");

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

sub flatten {
    map @$_, @_;
}
