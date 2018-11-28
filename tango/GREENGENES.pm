package GREENGENES;
use strict;
use warnings;
use parent "Taxonomy";
use Switch;

my %rankFromName = ( "rootrank" => 1,
		     "kingdom" => 2,
		     "phylum" => 3,
		     "class" => 4,
		     "order" => 5,
		     "family" => 6,
		     "genus" => 7,
		     "species" => 8,
                     "leafrank" => 9);

my %rankFromPrefix = ( "R" => 1,
		       "k" => 2,
		       "p" => 3,
		       "c" => 4,
		       "o" => 5,
		       "f" => 6,
		       "g" => 7,
		       "s" => 8);

my %nameFromRank;
while (my ($n, $r) = each %rankFromName) {
    $nameFromRank{$r} = $n;
}

my %defaultRanks;
for my $rName ( "rootrank", "kingdom", "phylum", "class", "order", "family", "genus", "species") {
    $defaultRanks{$rankFromName{$rName}} = 1;
}

sub getDefaultRanks {
    my %copy = %defaultRanks;
    return \%copy;
}

sub new {
    my ($class, $filename) = @_;
    my $genLins = generateLineages($filename);
    bless(Taxonomy::fromLineages($genLins), $class);
}

sub generateLineages {
    my $filename = shift;
    my $fh;

    if ($filename =~ /\.gz$/) {
        open($fh, "gunzip -c $filename |") || die "can't open pipe to $filename";
    } else {
        open($fh, $filename) || die "can't open $filename";
    }
    
    my $leafRank = $rankFromName{"leafrank"};
    my $leaf;
    my @lineage;
    my @parsed;

    my $par;
    my $parRank;
    my $child;
    my $childRank;
    my $prefix;
    my $problem;

    my $root = "R_root";
    my $rootRank = $rankFromName{"rootrank"};

    return sub {
	while (<$fh>) {
	    if (m/^>/) {
		@parsed = ($_ =~ /\s+(\w{1})\_{2}([^\;]+)/g);
		($leaf) = ($_ =~ /^>(\d+)/);

		$problem = 0;
		$par = $root;
		$parRank = $rootRank;
		@lineage = ($root, $rootRank);

		while (@parsed) {
		    $prefix = shift(@parsed);
		    $childRank = $rankFromPrefix{$prefix};
		    if (defined($childRank)) {
			$child = $prefix . "_" . shift(@parsed);
			if ($parRank < $childRank) {
			    push(@lineage, ($child, $childRank));
			    $par = $child;
			    $parRank = $childRank;
			}
			# Some lineages have a node (and its rank) repeated
			elsif ($parRank == $childRank && $par eq $child) {
			    next;
			}
			else {
			    $problem = 1;
			    print STDERR "Problem parsing lineage of $leaf\n";
			    last;
			}
		    }
		    else {
			$problem = 1;
			print STDERR "Unknown prefix '$prefix' while parsing lineage for $leaf\n";
			last;
		    }
		}
		if(!$problem) {
		    push(@lineage, ($leaf, $leafRank));
		    return \@lineage;
		}
	    }
	}
	close($fh);
	return undef;
    };
}

sub nodeInfo {
    my ($taxonomy, $node) = @_;
    my $nameRank = $nameFromRank{$taxonomy->rank($node)};
    return "$node ($nameRank)";
}

sub parseRank {
    my ($dummy, $rank) = @_;
    return $rankFromName{$rank} if exists($rankFromName{$rank});
    return $rank if exists($nameFromRank{$rank});
    return undef;
}

sub canMapTo {
    my ($taxonomy, $target) = @_;
    return uc($target) ~~ ["NCBI"];
}

sub generatePairs {
    (my $taxonomy, my %args) = @_;
    my $target = lc($args{'target'}) ||
	die "Greengenes::generatePairs requires a target argument";
    my $mappingFile = $args{'mappingFile'} ||
	die "Greengenes::generatePairs requires a mappingFile argument";

    if (!$taxonomy->canMapTo($args{'target'})) {
	die "Mapping from Greengenes to $target not available";
    }
    
    switch ($target) {
	case "ncbi" {
	    my $file = $args{'mappingFile'};
	    my $fh;
	    if ($file =~ /\.gz$/) {
		open($fh, "gunzip -c $file |") || die "Could not open $file: $!";
	    }
	    else {
		open($fh, "<", $file) || die "Could not open $file: $!\n";
	    }

	    return sub {
		local $/ = "BEGIN";
		while (<$fh>) {
		    if (m/ncbi_tax_id=(\d+).+prokMSA_id=(\d+)/gs) {
			return ($2, $1);
		    }
		}
		close($fh);
		return undef;
	    }
	}
	else {
	    die "Mapping from Greengenes to $target not available";
	}
    }
}

sub taxonomyFileName {
    return ["GREENGENES: http://greengenes.lbl.gov/Download/Sequence_Data/Fasta_data_files/current_GREENGENES_gg16S_unaligned.fasta.gz"];
}

sub ranksDocumentation {
    my $func = sub {
	my $r = shift;
	my $text = (exists($defaultRanks{$r}) ? "\t* " : "\t  ")
	    . "$nameFromRank{$r} ($r)";
	return $text;
    };
    my @lines = map {&$func($_)} (sort {$a <=> $b} keys %nameFromRank);
    unshift(@lines, "Possible ranks for Greengenes (ranks kept in default contraction marked with '*'):");
    return \@lines;
}

sub equalizeDocumentation {
    return ["From Greengenes to:",
	    "\tNCBI: http://greengenes.lbl.gov/Download/Sequence_Data/Greengenes_format/greengenes16SrRNAgenes.txt.gz"];
}

1;
