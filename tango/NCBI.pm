package NCBI;
use strict;
use warnings;
use Archive::Tar;
use POSIX "floor";
use parent "Taxonomy";

my %rankFromName = (
"rootrank" => 1,
"superkingdom" => 2,
"kingdom" => 3,
"subkingdom" => 4,
"superphylum" => 5,
"phylum" => 6,
"subphylum" => 7,
"superclass" => 8,
"class" => 9,
"subclass" => 10,
"infraclass" => 11,
"superorder" => 12,
"order" => 13,
"suborder" => 14,
"infraorder" => 15,
"parvorder" => 16,
"superfamily" => 17,
"family" => 18,
"subfamily" => 19,
"tribe" => 20,
"subtribe" => 21,
"genus" => 22,
"subgenus" => 23,
"species group" => 24,
"species subgroup" => 25,
"species" => 26,
"subspecies" => 27,
"varietas" => 28,
"forma" => 29
);

my %nameFromRank;
while (my ($n, $r) = each %rankFromName) {
    $nameFromRank{$r} = $n;
}

my %defaultRanks;
for my $rName ( "rootrank", "superkingdom", "phylum", "class", "order", "family", "genus", "species") {
    $defaultRanks{$rankFromName{$rName}} = 1;
}

sub getDefaultRanks {
    my %copy = %defaultRanks;
    return \%copy;
}

sub new {
    my ($class, $archiveName) = @_;

    my %parent = ();
    my %first_child = ();
    my %next_sibling = ();
    my %last_child = ();
    my %rank = ();
    
    my $par;
    my $child;
    my $childRank;

    my $nodes = getContentFromTar($archiveName, "nodes.dmp");

    while ($$nodes =~ m/(\d+)\t\|\t(\d+)\t\|\t([^\t]+)[^\n]*\n/gs) {
	$child = $1;
	$par = $2;
	$childRank = $3;

	$parent{$child} = $par;
	if ($child eq '1') {
	    $rank{$child} = $rankFromName{'rootrank'};
	}
	else {
	    if (exists $last_child{$par}) {
		$next_sibling{$last_child{$par}} = $child;
	    }
	    else {
		$first_child{$par} = $child;
	    }
	    $last_child{$par} = $child;
	    $rank{$child} = $rankFromName{$childRank};
	}
    }
    
    while (my $n = each %parent) {
        # Assign a rank to nodes without it.
        if (!defined $rank{$n}) {
            my @withoutRank = ($n);
            my $pn = $parent{$n};
            while (!defined $rank{$pn}) {
                unshift(@withoutRank, $pn);
                $n = $pn;
                $pn = $parent{$n};
            }
            my $bottom = $rank{$pn};
            my $top = floor($bottom + 1);
            my $amount = ($top - $bottom) / 2;
            my $inc = $amount / @withoutRank;
            my $val = $bottom;
            foreach my $n2 (@withoutRank) {
                $val += $inc;
                $rank{$n2} = $val;
            }
        }
    }

    # Create the 'toContracted' mapping
    my $toContracted = parseMerged($archiveName);
    while (my ($key, $val) = each %{$toContracted}) {
	if (!defined($parent{$val})) {
	    print "$key merged to node $val not present in taxonomy.\n";
	}
    }

    while (my $node = each %parent) {
	$toContracted->{$node} = $node;
    }
    
    my $name = parseNames($archiveName);

    my $taxo = Taxonomy->new(
	'root' => '1',
	'parent' => \%parent,
	'first_child' => \%first_child,
	'next_sibling' => \%next_sibling,
	'rank' => \%rank,
	'toContracted' => $toContracted,
	'checkLineages' => 1);

    $taxo->{'name'} = $name;
    bless($taxo, $class);
}

sub name {
    my ($taxonomy, $node) = @_;
    return $taxonomy->{'name'}->{$node};
}

sub nodeInfo {
    my ($taxonomy, $node) = @_;
    my $name = $taxonomy->name($node);
    my $nameRank = $nameFromRank{$taxonomy->rank($node)};
    $nameRank = "no rank" if (!defined($nameRank));
    return "$node ($nameRank: $name)";
}

sub copyNames {
    my ($target, $source) = @_;
    my %name = ();
    for my $node (@{$target->getNodes()}) {
 	$name{$node} = $source->name($node);
    }
    $target->{'name'} = \%name;
    bless($target, ref($source));
}

sub contract {
    my $oriTaxo = $_[0];
    my $contracted = Taxonomy::contract(@_);
    return $contracted->copyNames($oriTaxo);
}

sub restrict {
    my $oriTaxo = $_[0];
    my $restricted = Taxonomy::restrict(@_);
    $restricted->copyNames($oriTaxo) if (defined($restricted));
    return $restricted;
}

sub parseRank {
    my ($dummy, $rank) = @_;
    return $rankFromName{$rank} if exists($rankFromName{$rank});
    return $rank if exists($nameFromRank{$rank});
    return undef;
}

sub parseMerged {
    my $archiveName = shift;
    my %merged = ();
    my $content = getContentFromTar($archiveName, "merged.dmp");
    while ($$content =~ m/(\d+)\t\|\t(\d+)\t\|\n/gs) {
	$merged{$1} = $2;
    }

    return \%merged;
}

sub parseNames {
    my $archiveName = shift;
    my $content = getContentFromTar($archiveName, "names.dmp");
    my $taxid;
    my $name;
    my $uniqueName;
    my $nameClass;
    my %name = ();


    while ($$content =~ m/(\d+)\t\|\t([^\t]+)\t\|\t([^\t]*)\t\|\t([^\t]+)\t\|\n/gs) {
	$taxid = $1;
	$name = $2;
	$uniqueName = $3;
	$nameClass = $4;
	if ($nameClass eq "scientific name") {
	    $name{$taxid} = $uniqueName ? $uniqueName : $name;
	}
    }
    return \%name;
}

sub getContentFromTar {
    my ($archiveName, $fileName) = @_;
    my $iter = Archive::Tar->iter($archiveName, {filter => qr/$fileName/} );
    if (defined($iter)) {
	my $file;
	while (my $f = $iter->() ) {
	    if ($f->name() eq $fileName) {
		$file = $f;
		last;
	    }
	}
	return $file->get_content_by_ref() if (defined($file));
    }
    die "Could not find $fileName in $archiveName";
}


sub taxonomyFileName {
    return ["NCBI: ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz"];
}

sub ranksDocumentation {
    my $func = sub {
	my $r = shift;
	my $text = (exists($defaultRanks{$r}) ? "\t* " : "\t  ")
	    . "$nameFromRank{$r} ($r)";
	return $text;
    };
    my @lines = map {&$func($_)} (sort {$a <=> $b} keys %nameFromRank);
    unshift(@lines, "Possible ranks for NCBI (ranks kept in default contraction marked with '*'):");
    return \@lines;
}

1;
