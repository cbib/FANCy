package RDP;
use strict;
use warnings;
use parent "Taxonomy";
use Switch;

my %rankFromName = ( "rootrank" => 1,
		     "domain" => 2,
		     "phylum" => 3,
		     "class" => 4,
		     "subclass" => 5,
		     "order" => 6,
		     "suborder" => 7,
		     "family" => 8,
		     "genus" => 9,
		     "species" => 10);

my %rankPrefix = ( "rootrank" => "R_",
		   "domain" => "k_",
		   "phylum" => "p_",
		   "class" => "c_",
		   "subclass" => "sc_",
		   "order" => "o_",
		   "suborder" => "so_",
		   "family" => "f_",
		   "genus" => "g_",
		   "species" => "",);

my %nameFromRank;
while (my ($n, $r) = each %rankFromName) {
    $nameFromRank{$r} = $n;
}

my %defaultRanks;
for my $rName ( "rootrank", "domain", "phylum", "class", "order", "family", "genus", "species") {
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

    my $speciesRank = $rankFromName{"species"};
    my $species;
    my @lineage;
    my $rankName;
    my $rankVal;
    
    return sub {
	while (<$fh>) {
	    if (m/>(S\d+).*Lineage=(.+)$/) {
		@lineage = split(";", $2);
		# If the number of elements in @lineage is odd, the last
		# node has no rank (usually an unclassified something)
		pop(@lineage) if (@lineage % 2 == 1);
		
		for (my $i = 0; $i < @lineage; $i += 2) {
		    my $rankName = $lineage[$i + 1];
		    $rankVal = $rankFromName{$rankName};
		    if (defined($rankVal)) {
			$lineage[$i] = $rankPrefix{$rankName} . $lineage[$i];
			$lineage[$i + 1] = $rankVal;
		    }
		    else {
			print STDERR "Warning: problem reading lineage of $1.";
			last;
		    }
		}
		push(@lineage, ($1, $speciesRank));
		
		return \@lineage;		
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
	die "RDP::generatePairs requires a target argument";
    my $mappingFile = $args{'mappingFile'} ||
	die "RDP::generatePairs requires a mappingFile argument";

    if (!$taxonomy->canMapTo($args{'target'})) {
	die "Mapping from RDP to $target not available";
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
                local $/ = "LOCUS";
                while (<$fh>) {
                    if($_ =~ m/\s+(\S+).*ORGANISM.*db_xref="\S+:(\d+)"/gs) {
                        return ($1, $2);
                    }
                }
                close ($fh);
                return undef;
            };
	}
	else {
	    die "Mapping from RDP to $target not available";
	}
    }
}

sub taxonomyFileName {
    return ["RDP: http://rdp.cme.msu.edu/misc/resources.jsp (fasta, combined, unaligned).",
	    "\tE.g.: http://rdp.cme.msu.edu/download/release10_31_unaligned.fa.gz"];
}

sub ranksDocumentation {
    my $func = sub {
	my $r = shift;
	my $text = (exists($defaultRanks{$r}) ? "\t* " : "\t  ")
	    . "$nameFromRank{$r} ($r)";
	return $text;
    };
    my @lines = map {&$func($_)} (sort {$a <=> $b} keys %nameFromRank);
    unshift(@lines, "Possible ranks for RDP (ranks kept in default contraction marked with '*'):");
    return \@lines;
}

sub equalizeDocumentation {
    return ["From RDP to:",
	    "\tNCBI: http://rdp.cme.msu.edu/misc/resources.jsp (genbank, combined, unaligned).",
	    "\t\tE.g.: http://rdp.cme.msu.edu/download/release10_31_unaligned.gb.gz"];
}

1;
