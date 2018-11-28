package Taxonomies;
use warnings;
use strict;
use GREENGENES;
use NCBI;
use Newick;
use RDP;

my %classes = ("greengenes" => "GREENGENES",
	       "ncbi" => "NCBI",
	       "newick" => "Newick",
	       "rdp" => "RDP");

sub getTaxonomyClass {
    return $classes{lc(shift)};
}

sub isValidType {
    return exists($classes{lc(shift)});
}

sub getAllTypes {
    return sort(keys(%classes));
}

1;
