package Taxonomy;
use warnings;
use strict;
use Storable;

# Parse a taxonomy from a file and preprocess it to be able to query
# it for LCA, LCA-Skeleton-Tree, etc.
sub new {
    my $class = shift;
    my %args = (checkLineages => 0, @_);
    my $root = $args{'root'} || die "Taxonomy::new requires a root argument";
    my $parent = $args{'parent'} || die "Taxonomy::new requires a parent argument";
    my $first_child  = $args{'first_child'} || die "Taxonomy::new requires a first_child argument";
    my $next_sibling  = $args{'next_sibling'} || die "Taxonomy::new requires a next_sibling argument";
    my $rank = $args{'rank'} || die "Taxonomy::new requires a rank argument";
    my $checkLineages = $args{'checkLineages'};
    my %preorder = ();
    my %num_desc_leaves = ();
    # $toContracted: If not undef, must be a hash mapping all the
    # 'original' nodes to a node in this taxonomy
    my $toContracted = $args{'toContracted'};

    # Preorder traversal
    my @stack = ($root);
    my @stackRanks = ($rank->{$root});
    my $pre = 1;
    

    my %toDelete = ();
    my %parentsToDelete = ();

    while (@stack) {
    	my $par = pop @stack;
        my $parRank = $rank->{$par};
    	$preorder{$par} = $pre++;

	for (my $child = $first_child->{$par}; defined $child; $child = $next_sibling->{$child}) {
	    if ($checkLineages && $parRank >= $rank->{$child}) {
		$toDelete{$child} = 1;
		$parentsToDelete{$par} = 1;
	    }
	    else {
		push(@stack, $child);
	    }
	}
    }
    
    while (my $par = each %parentsToDelete) {
	my $last_child = '';
	for (my $child = $first_child->{$par}; defined $child; $child = $next_sibling->{$child}) {
	    if ($toDelete{$child}) {
		if ($first_child->{$par} eq $child) {
		    $first_child->{$par} = $next_sibling->{$first_child->{$par}};
		}
		@stack = ($child);
		while (@stack) {
		    my $par2 = pop @stack;
		    $toDelete{$par2} = 1;
		    for (my $child2 = $first_child->{$par2}; defined $child2; $child2 = $next_sibling->{$child2}) {
			push(@stack, $child2);
		    }
		}
	    }
	    else {
		if ($last_child) {
		    $next_sibling->{$last_child} = $child;
		}
		else {
		    $first_child->{$par} = $child;
		}
		$last_child = $child;
	    }
	}
	delete $next_sibling->{$last_child} if $last_child;
    }

    my @nodesToDelete = keys %toDelete;
    delete @{$parent}{@nodesToDelete};
    delete @{$first_child}{@nodesToDelete};
    delete @{$next_sibling}{@nodesToDelete};
    delete @{$rank}{@nodesToDelete};
    if (defined $toContracted) {
	my @toConDelete = grep {$toDelete{$toContracted->{$_}}} keys %{$toContracted};
	delete @{$toContracted}{@toConDelete};
    }

    # Compute the number of descendant leaves for each node
    my @sortedPostorder = sort {$preorder{$b} <=> $preorder{$a}} keys(%preorder);
    foreach my $par (@sortedPostorder) {
	if (!$first_child->{$par}) {
	    $num_desc_leaves{$par} = 1;
	}
	else {
	    my $total = 0;
	    for (my $child = $first_child->{$par}; defined $child; $child = $next_sibling->{$child}) {
		$total += $num_desc_leaves{$child};
	    }
	    $num_desc_leaves{$par} = $total;
	}
    }
    
    bless {
	'parent' => $parent,
	'first_child' => $first_child,
	'next_sibling' => $next_sibling,
	'rank' => $rank,
	'preorder' => \%preorder,
	'num_desc_leaves' => \%num_desc_leaves,
	'root' => $root,
	'toContracted' => $toContracted
    }, $class;
}

# Build a Taxonomy object from its lineages. Its argument is a
# function reference that returns a new lineage each time it's called,
# or undef when there are no remaining lineages.
#
# A lineage is a list where even elements are node names, and odd
# elements are the rank of its preceding element. It contains a path
# from the root to a leaf.

sub fromLineages {
    my $generateLineages = shift;
    my %parent = ();
    my %rank = ();
    my %first_child = ();
    my %next_sibling = ();
    my $root;
    my $rootRank;

    my %last_child = ();
    my %alternative_names = ();

    my $par;
    my $parRank;
    my $child;
    my $childRank;

    my $lineage = $generateLineages->();

    if (defined($lineage)) {
	$root = $lineage->[0];
	$rootRank = $lineage->[1];
	$parent{$root} = $root;
	$rank{$root} = $rootRank;
    }
    else {
	die "Cannot build a Taxonomy object without at least a lineage.";
    }

    while (defined($lineage)) {
	$par = shift(@{$lineage});
	$parRank = shift(@{$lineage});

	if ($par ne $root || $parRank != $rootRank) {
	    die "All lineages should start from the root, but lineage ",
	    "for leaf $lineage->[-2] starts from $par.";
	} 

	while (@{$lineage}) {
	    $child = shift(@{$lineage});
	    $childRank = shift(@{$lineage});

	    if ($parRank < $childRank) {
		# Disambiguate the node name if there is a collision
		if (defined($parent{$child}) && $parent{$child} ne $par) {
		    if (!defined($alternative_names{$child})) {
			$alternative_names{$child} = [$child];
		    }
		    my $names = $alternative_names{$child};
		    my $found = 0;
		    
		    for my $name (@{$names}) {
			if ($parent{$name} eq $par) {
			    $child = $name;
			    $found = 1;
			    last;
			}
		    }
		    if (!$found) {
			my $n = scalar(@{$names});
			$child = $child . " [disambiguated $n]";
			push(@{$names}, $child);
		    }
		}

		if (!defined($parent{$child})) { # First time we see child
		    if (defined $last_child{$par}) {
			$next_sibling{$last_child{$par}} = $child;
		    }
		    else {
			$first_child{$par} = $child;
		    }
		    $parent{$child} = $par;
		    $last_child{$par} = $child;
		    $rank{$child} = $childRank;
		}

		$par = $child;
		$parRank = $childRank;
	    }
	    else { # $parRank >= $childRank
		print STDERR "Discarding lineage for leaf $lineage->[-2] ",
		"due to a problem with the ranks of $par (rank $parRank) and $child (rank $childRank)\n";
	    }
	}
	$lineage = $generateLineages->();
    }

    while ((my $name, my $others) = each %alternative_names) {
	my $n = scalar(@{$others});
	print STDERR "There were $n different nodes with the name: $name. New names:\n";
	for my $other (@{$others}) {
	    print "\t$other (with parent: $parent{$other})\n";
	}
    }

    return Taxonomy->new(
	'root' => $root,
	'parent' => \%parent,
	'first_child' => \%first_child,
	'next_sibling' => \%next_sibling,
	'rank' => \%rank,
	'checkLineages' => 0);
}

sub root {
    my ($taxonomy) = @_;
    return $taxonomy->{'root'};
}

sub isRoot {
    my ($taxonomy, $node) = @_;
    return ($taxonomy->{'root'} eq $node);
}

sub isLeaf {
    my ($taxonomy, $node) = @_;
    return (! defined($taxonomy->{'first_child'}->{$node}));
}

sub isInner {
    my ($taxonomy, $node) = @_;
    return (defined($taxonomy->{'first_child'}->{$node}));
}

sub children {
    my ($taxonomy, $node) = @_;
    my @children = ();
    for (my $child = $taxonomy->{'first_child'}->{$node}; defined $child;
	   $child = $taxonomy->{'next_sibling'}->{$child}) {
	push(@children, $child);
    }
    return \@children;
}

sub firstChild {
    my ($taxonomy, $node) = @_;
    return $taxonomy->{'first_child'}->{$node};
}

sub nextSibling {
    my ($taxonomy, $node) = @_;
    return $taxonomy->{'next_sibling'}->{$node};
}

sub parent {
    my ($taxonomy, $node) = @_;
    return $taxonomy->{'parent'}->{$node};
}

sub rank {
    my ($taxonomy, $node) = @_;
    return $taxonomy->{'rank'}->{$node};
}

sub isPresent {
    my ($taxonomy, $node) = @_;
    return $taxonomy->{'parent'}->{$node};
}

sub numDescLeaves {
    my ($taxonomy, $node) = @_;
    return $taxonomy->{'num_desc_leaves'}->{$node};
}

# Subclasses can specialize this method to give more information about
# a node. It must return a string
sub nodeInfo {
    my ($taxonomy, $node) = @_;
    my $rank = $taxonomy->rank($node);
    return "$node ($rank)";
}

# If given a scalar, return the node to which the argument was
# contracted (the lowest ancestor present in the contracted taxonomy),
# or undef if it was not present in the expanded (original) taxonomy.
#
# If given a reference to a list, return a (reference to a) list with
# the nodes to which some node in the input list was contracted, and a
# (reference to a) list with the nodes in the input list that were not
# present in the expanded (original) taxonomy.

sub toContracted {
    my ($taxonomy, $arg) = @_;
    my $toContracted = $taxonomy->{'toContracted'};
    if (ref($arg) eq 'ARRAY') {
	my %contracted;
	my %missing;
	my $cont;
	if (defined($toContracted)) {
	    for my $node (@{$arg}) {
		$cont = $toContracted->{$node};
		if ($cont) {
		    $contracted{$cont} = 1;
		}
		else {
		    $missing{$node} = 1;
		}
	    }
	}
	else {
	    for my $node (@{$arg}) {
		if ($taxonomy->isPresent($node)) {
		    $contracted{$node} = 1;
		}
		else {
		    $missing{$node} = 1;
		}
	    }
	}
	my @arrCont = keys(%contracted);
	my @arrMiss = keys(%missing);
	return (\@arrCont, \@arrMiss);
    }
    else { # arg is just a node
	return $toContracted->{$arg} if (defined($toContracted));
	return $arg if ($taxonomy->isPresent($arg));
	return undef;
    }
}


# Return a hash with the inverse function of toContracted, or the
# identity if toContracted is undef.

sub getInvertedToContracted {
    my $taxonomy = shift;
    my %inverted = ();
    if (defined $taxonomy->{'toContracted'}) {
	while ( my ($expanded, $contracted) = each %{$taxonomy->{'toContracted'}} ) {
	    $inverted{$contracted}{$expanded} = 1;
	}
    }
    else {
	for my $node (@{$taxonomy->getNodes()}) {
	    $inverted{$node}{$node} = 1;
	}
    }
    return \%inverted;
}


sub getLineage {
    my ($taxonomy, $node) = @_;
    my @lineage = ();
    while ($node ne $taxonomy->root()) {
        push (@lineage, $node);
        $node = $taxonomy->parent($node);
    }
    push (@lineage, $taxonomy->root());
    return \@lineage;
}

# Given a preprocessed taxonomy, compute the Lowest Common Ancestor of
# two of its nodes.
sub lca {
    my ($taxonomy, $n1, $n2) = @_;
    my $comp;
    
    while ($n1 ne $n2) {
        $comp = $taxonomy->rank($n1) <=> $taxonomy->rank($n2);
        if ($comp == 0) {
            $n1 = $taxonomy->parent($n1);
            $n2 = $taxonomy->parent($n2);
        }
        elsif ($comp == 1) {
            $n1 = $taxonomy->parent($n1);
        }
        else {
            $n2 = $taxonomy->parent($n2);
        }
    }
    return $n1;
}

# return the LCA of all the elements of the list, or undef for the
# empty list.
sub lcaList {
    my ($taxonomy, $list) = @_;
    return undef if (!@{$list});

    my $n1 = shift(@{$list});
    for my $n2 (@{$list}) {
	$n1 = $taxonomy->lca($n1, $n2);
    }
    return $n1;
}

sub getNodes {
    my $taxonomy = shift;
    my @nodes = keys %{$taxonomy->{'parent'}};
    return \@nodes;
}

# Subclasses that can be contracted to keep just nodes with canonical
# ranks must specialize this function. It must return a reference to a
# hash where the keys are the ranks that must be kept after
# contraction.
sub getDefaultRanks {
    return undef;
}

sub sortPreorder {
    my ($taxonomy, $nodes) = @_;
    my @sorted = sort {$taxonomy->{'preorder'}->{$a} <=> $taxonomy->{'preorder'}->{$b}} @{$nodes};
    return \@sorted;
}

sub contract {
    my $taxonomy = shift;
    my $class = ref($taxonomy);
    my %args = (keepLeaves => 0, ranks2keep => $taxonomy->getDefaultRanks(), @_);
    my $keepLeaves = $args{'keepLeaves'};
    my $ranks2keep = $args{'ranks2keep'} ||
	die "Taxonomy::contract: Taxonomies of type $class must be given an explicit hash of ranks to keep";

    my %parent = ();
    my %first_child = ();
    my %next_sibling = ();
    my %rank = ();
    my %last_child = ();
    my %toContracted = ();

    my $invertedToContracted = $taxonomy->getInvertedToContracted();

    my $root = $taxonomy->root();
    my @stack = ($root);
    $parent{$root} = $root;
    $rank{$root} = $taxonomy->rank($root);
    $toContracted{$root} = $root;
    
    my $par;
    
    # Nodes in @stack already have parent, rank and toContracted.
    while (@stack) {
	$par = pop @stack;
	my $parRank = $rank{$par};
	my @children = @{$taxonomy->children($par)};
	while (@children) {
	    my $child = shift @children;
	    my $childRank = $taxonomy->rank($child);
	    if ($parRank < $childRank) {
		if ($ranks2keep->{$childRank}
		    || ($keepLeaves && $taxonomy->isLeaf($child))) {

		    $parent{$child} = $par;
		    $rank{$child} = $childRank;
		    $toContracted{$child} = $child;

		    if ($last_child{$par}) {
			$next_sibling{$last_child{$par}} = $child;
		    }
		    else {
			$first_child{$par} = $child;
		    }
		    $last_child{$par} = $child;

		    if ($taxonomy->isInner($child)) {
			push(@stack, $child);
		    }
		}
		else {
		    # Map $child (and all the original nodes mapped to $child) to $par
		    for my $ori (keys %{$invertedToContracted->{$child}}) {
			$toContracted{$ori} = $par;
		    }

		    # Skip $child, but search its children for nodes to keep.
		    if ($taxonomy->isInner($child)) {
			push(@children, @{$taxonomy->children($child)});
		    }
		}
	    }
	    else {
		print "Wrong lineage: discarding $child and its descendants.\n";
	    }
	}
    }

    bless Taxonomy->new(
	'root' => $root,
	'parent' => \%parent,
	'first_child' => \%first_child,
	'next_sibling' => \%next_sibling,
	'rank' => \%rank,
	'toContracted' => \%toContracted,
	'checkLineages' => 0),
	$class;
}


# Restrict a taxonomy to the lineages of a list of "determining"
# nodes. Every node in the resulting tree is an ancestor of a
# "determining" node. A node not present in the resulting tree will
# have a 'toContracted' only if it is a descendant of a "determining"
# node. Its 'toContracted' will be its lowest ancestor in the original
# tree that is present in the resulting tree.
#
# Arguments: reference to the list with the "determining" nodes.
#
# Return undef if no node in the list was present in the taxonomy.

sub restrict {
    my ($oriTaxo, $nodes2keep) = @_;
    my $class = ref($oriTaxo);

    my ($contractedNodes, $missingNodes) = $oriTaxo->toContracted($nodes2keep);

    if (!@{$contractedNodes}) {
	print STDERR "Taxonomy::restrict: no node present in the taxonomy.\n";
	return undef;
    }
    if (@{$missingNodes}) {
	print STDERR "Taxonomy::restrict: nodes not present in the taxonomy:\n",
	join("\n", @{$missingNodes});
    }

    my %determiningNodes = ();
    map { $determiningNodes{$_} = 1 } @{$contractedNodes};

    my $genLineages = sub {
	my $determining = each %determiningNodes;
	if (defined $determining) {
	    my @res = ();
	    for my $node (@{$oriTaxo->getLineage($determining)}) {
		unshift(@res, ($node, $oriTaxo->rank($node)));
	    }
	    return \@res;
	}
	return undef;
    };

    my $restrictedTaxo = fromLineages($genLineages);
    
    # Compute the 'toContracted' with a traversal of the original tree.
    my $inverted = $oriTaxo->getInvertedToContracted();
    my %toContracted = ();

    # use 'local' instead of 'my' to avoid memory leak. See:
    # http://www.perlmonks.org/?node_id=696592
    local *computeToContracted = sub {
    	my ($node, $determiningAncestor) = @_;
    	if ($restrictedTaxo->isPresent($node) || $determiningAncestor) {
    	    my $det = $determiningAncestor || $determiningNodes{$node};
    	    my %pending = ($node => 1);
    	    for my $child (@{$oriTaxo->children($node)}) {
    		my $pendingChild = computeToContracted($child, $det);
		while (my $k = each %{$pendingChild}) {
		    $pending{$k} = 1;
		}
    	    }
    	    if ($restrictedTaxo->isPresent($node)) {
    		for my $pend (keys %pending) {
    		    for my $expanded (keys %{$inverted->{$pend}}) {
    			$toContracted{$expanded} = $node;
    		    }
    		}
    		return {};
    	    }
    	    else {
    		return \%pending;
    	    }
    	}
    	return {}; # Discard this subtree
    };

    computeToContracted($oriTaxo->root(), 0);

    $restrictedTaxo->{'toContracted'} = \%toContracted;
    bless($restrictedTaxo, $class);
}

# Subclasses must specialize this method. If the argument is a valid
# rank (or the name of a valid rank), return it, otherwise return
# undef
sub parseRank {
    return undef;
}

sub serialize {
    my ($taxonomy, $fileName) = @_;
    store($taxonomy, $fileName);
}

sub deserialize {
    my $fileName = shift;
    my $taxonomy = retrieve($fileName);
    die "Could not deserialize a taxonomy from $fileName.\n" if (!$taxonomy);
    return $taxonomy;
}


### Information about the taxonomy

# Number of nodes of a taxonomy.
sub numNodes {
    my $taxonomy = shift;
    return (scalar (keys %{$taxonomy->{'parent'}}));
}

# Number of leaves of a taxonomy.
sub numLeaves {
    my $taxonomy = shift;
    my $num = 0;
    while (my ($key, $val) = each %{$taxonomy->{'parent'}}) {
    	if ($taxonomy->isLeaf($key)) {
    	    $num++;
    	}
    }
    return $num;
}

# Number of leaves that have the lowest rank in the taxonomy.
sub numLeavesLowestRank {
    my $taxonomy = shift;
    my $lastRank = $taxonomy->rank($taxonomy->root());
    my $rank;
    my $num = 0;
    while (my ($key, $val) = each %{$taxonomy->{'parent'}}) {
	$rank = $taxonomy->rank($key);
	if ($rank == $lastRank) {
	    $num++;
	}
	elsif ($rank > $lastRank) {
	    $lastRank = $rank;
	    $num = 1;
	}
    }
    return $num;
}

# Conversion between taxonomies

# Subclasses whose nodes can be mapped to nodes of other taxonomy
# types must specialize this function. It receives the name of the
# taxonomy class it must map to, and it must return true if the
# mapping is possible, false otherwise.

sub canMapTo {
    return 0;
}

# Subclasses whose nodes can be mapped to other taxonomy types must
# specialize this function. It receives a hash with keys:
# * 'target': type of the taxonomy object.
# * 'mappingFile': file with the mapping
#
# It must return a function that returns a pair of nodes
# (sourceNode, targetNode) every time it is called, or undef when no
# more pairs are available.

sub generatePairs {
    return undef;
}

# Documentation for the taxonomy

# Subclasses must specialize the following functions. They must return
# a reference to a list, with each element being a line of text to
# print.

# Name of the file from which taxonomies of this type can be parsed.
sub taxonomyFileName {
    return [];
}

# Information about the possible ranks in taxonomies of this type.
sub ranksDocumentation {
    return [];
}

# Information about the mappings available for this type.
sub equalizeDocumentation {
    return [];
}

1;
