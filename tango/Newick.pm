package Newick;
use strict;
use warnings;
use parent "Taxonomy";

# Read a newick file into a Taxonomy object. All OTUs must be labeled.
sub new {
    # Each token must be followed by one of these:
    #
    #    name : ")" | "," | ";"
    #    "("  : "(" | name
    #    ","  : "(" | name
    #    ")"  : name (as all nodes must be labelled).
    #
    # When parsing the name of a node, we will discard the length of
    # the branch, if present.

    my $class = shift;
    my $filename = shift;
    my $fh;

    if ($filename =~ /\.gz$/) {
	open($fh, "gunzip -c $filename |") || die "can't open pipe to $filename";
    } else {
	open($fh, $filename) || die "can't open $filename";
    }

    my %parent = ();
    my %rank = ();
    my %first_child = ();
    my %next_sibling = ();

    my $line = <$fh>;
    my $line_num = 1;
    my $prev; # previous char
    my $curr; # current char
    my $start_line; # Line at which a name starts.
    my $start_char; # Char at which a name starts.

    my @siblings = ([]); # Stack of lists of siblings
    my $node;
    my $currRank = 1;
    my %specialChar = ("(" => 1, ")" => 1, "," => 1, ":" => 1, ";" => 1);

    my $parseError = sub {
	my $char = pos($line);
	if (!defined($line)) {
	    if ($curr eq '"' || $curr eq "'") {
		print "Could not find closing quote for $curr at line $start_line,"
		    . " char $start_char.\n";
	    }
	    else {
		print "Reached end of file without finding a (nonquoted) semicolon.\n";
	    }
	    exit(1);
	}
	elsif ($currRank < 1) {
	    print "Closing unopened parenthesis at line $line_num, character $char.\n";
	    exit(1);
	}
	elsif ($curr eq ";" && $currRank != 1) {
	    print "Missing closing parenthesis at line $line_num, character $char.\n";
	    exit(1);
	}
	elsif ($prev eq "name" && !($curr ~~ [")", ",", ";"])) {
	    print "Found '$curr' while expecting ')', ',' or ';' after OTU name"
		. " at line $line_num, character $char.\n";
	    exit(1);
	}
	elsif ($prev ~~ ["(", ","] && !($curr ~~ ["(", "name"])) {
	    print "Found '$curr' while expecting '(' or OTU name, after '$prev'"
		 . " at line $line_num, character $char.\n";
	    exit(1);
	}
	elsif ($prev eq ")" && $specialChar{$curr}) {
	    print "Found '$curr' while expecting OTU name at line $line_num,"
		 . " character $char. All OTUs must be named.\n";
	    exit(1);
	}
	else { # This should never happen
	    print "Unknown error at line $line_num, character $char.\n";
	    exit(1);
	}
    };

    my $readName = sub {
	$start_line = $line_num;
	$start_char = pos($line);
	
	my $name;
	my $regex;

	if ($curr eq '"' || $curr eq "'") { # Read until closing quotes
	    $name = "";
	    $regex = "\\G([^$curr]*)";
	}
	else {
	    $name = $curr;
	    $regex = "\\G([^\\(\\),:;]*)";
	}
	while ($line =~ m/$regex/gc) {
	    $name = $name.$1;
	    if ($line =~ m/\G$/gc) {
		$line = <$fh>;
		$line_num++;
		&$parseError() if (!defined($line));
	    }
	    elsif ($line =~ m/\G$curr/gc){ # Discard the closing quote
	    	last;
	    }
	}

	&$parseError() if (!$name);
	
	# Discard branch length
	$line =~ m/\G:\d*(\.\d+)?/gc;
	
	return $name;
    };
    
    # Discard initial comments
    while (defined($line) && $line =~ m/^#/) {
	$line = <$fh>;
	$line_num++;
    }
    &$parseError() if (!defined($line));

    # Initial $curr to allow parsing trees with just the root as well
    # as trees with some children.
    $curr = ",";

    while ($curr ne ";") {
	# Read next char
	if ($line !~ m/\G\s*(.)/gc) {
	    $line = <$fh>;
	    $line_num++;
	    &$parseError() if (!defined($line));
	    next;
	}

	$prev = $curr;
	$curr = $1;

	if ($prev eq "name") {
	    if ($curr eq ")") {
		$currRank--;
		&$parseError() if ($currRank < 1);
	    }
	    elsif ($curr eq ";") {
		&$parseError() if $currRank != 1;
	    }
	    elsif ($curr ne ",") {
		&$parseError();
	    }
	}
	elsif ( ($prev eq "," || $prev eq "(") && $curr eq "(" ) {
	    push(@siblings, []);
	    $currRank++;
	}
	elsif ( !$specialChar{$curr} # $curr is name
		&& ($prev eq "," || $prev eq "(" || $prev eq ")") ) {

	    $node = &$readName();
	    if (defined($rank{$node})) {
		print "Repeated name for OTU at line $line_num, character "
		    . pos($line) . ". All OTUs must have a unique name.\n";
		exit(1);
	    }
	    $rank{$node} = $currRank;

	    if ($prev eq ")") {
		my $prevChild;
		my $children = pop(@siblings);
		foreach my $child (@{$children}) {
		    $parent{$child} = $node;
		    if (!defined($prevChild)) {
			$first_child{$node} = $child;
		    }
		    else {
			$next_sibling{$prevChild} = $child;
		    }
		    $prevChild = $child;
		}
	    }
	    $curr = "name";
	    
	    # Add $node to the lowest level of @siblings
	    push(@{$siblings[-1]}, $node);
	}
	else {
	    &$parseError();
	}
    }
    $parent{$node} = $node;

    close($fh);

    bless Taxonomy->new(
	root => $node,
	parent => \%parent,
	first_child => \%first_child,
	next_sibling => \%next_sibling,
	rank => \%rank,
	checkLineages => 0),
	$class;
}

# Write a taxonomy in Newick format.
sub toNewick {
    my $taxonomy = shift;
    my $outFile = shift;

    my %args = ('sanitizer' => \&sanitizer, @_);
    my $sanitizer = $args{'sanitizer'};

    open(my $outHandle, ">", $outFile) or die "Can't open $outFile: $!";

    # Postorder iterative traversal
    my $prev = $taxonomy->root();
    my $curr = $taxonomy->firstChild($prev);
    my $isLeaf; # is $curr a leaf?
    my $goingUp; # are we moving up in the traversal?
    my $first;
    my $nextSibling;
    my $sanitized;

    if (defined($curr)) { # Root has at least a child
	while ($taxonomy->parent($curr) ne $curr) {
	    $isLeaf = $taxonomy->isLeaf($curr);
	    $first = $taxonomy->firstChild($prev);
	    $nextSibling = $taxonomy->nextSibling($prev);

	    if (defined($first) && ($curr eq $first)) {
		$goingUp = 0;
		print $outHandle "(";
	    }
	    elsif (defined($nextSibling) && ($curr eq $nextSibling)) {
		$goingUp = 0;
		print $outHandle ",";
	    }
	    else {
		$goingUp = 1;
		print $outHandle ")" if (!$isLeaf);
	    }

	    $prev = $curr;
	    if ($isLeaf || $goingUp) {
		my $sanitized = &$sanitizer($curr);
		print $outHandle "$sanitized";

		$curr = $taxonomy->nextSibling($prev);
		$curr = $taxonomy->parent($prev) if (! defined($curr));
	    }
	    else {
		$curr = $taxonomy->firstChild($prev);
	    }
	}
	print $outHandle ")";
    }
    $sanitized = &$sanitizer($taxonomy->root());
    print $outHandle "$sanitized;\n";
    close($outHandle);
}

sub sanitizer {
    my $name = shift;
    if ($name =~ m/[\(\),:;\s]/) {
	$name =~ s/"/_/g;
	$name = "\"$name\"";
    }
    return $name;
}

sub parseRank {
    my ($dummy, $rank) = @_;
    return $rank if ($rank =~ m/^\d+$/);
    return undef;
}

sub taxonomyFileName {
    return ["Newick: any newick file."];
}

sub ranksDocumentation {
    return ["Possible ranks for Newick: positive integers representing the depth of a node (1 for the root)."];
}

1;
