package TaxoAssignment;
use GREENGENES;
use RDP;
use NCBI;
use UNITE;
use warnings;
use strict;
use Storable ;

# Given a preprocessed taxonomy, compute the weighted LCA Skeleton
# Tree of a set of nodes (that belong to the taxonomy). The second
# argument is a reference to a hash with the node id as key and the
# weight of the node as value. Return a reference to a hash with all
# the nodes in the skeleton tree, with node id as key and the sum of
# the weight of all the original nodes that are descendant from this
# node as value.

sub skeletonTree {
    my ($taxonomy, $numDesc) = @_;
    my %numDescMatches = %{$numDesc}; # copy
    my @nodeIds = keys(%numDescMatches);
    my $rights = $taxonomy->sortPreorder(\@nodeIds);


    if (@{$rights} < 2) {
        return \%numDescMatches;
    }

    # The LCA of a node and the node to its left is cached at
    # "cachedSomething" (e.g. cachedRight = LCA(left, right)).

    my @lefts = ();
    my @cachedLefts = ();
    my $left = shift @{$rights};
    my $cachedLeft = $left;
    my $right = shift @{$rights};
    my $cachedRight = $taxonomy->lca($left, $right);

    my $merge = sub {
        #Merge: nodes are sorted in preorder, so right cannot be equal
        #to LCA(left, right).
        if ($left ne $cachedRight) {
            $numDescMatches{$cachedRight} += $numDescMatches{$left};
        }
        $numDescMatches{$cachedRight} += $numDescMatches{$right};
    };

    while (@lefts or @{$rights}) {
        if (!@{$rights}) {
            &$merge();
            $right = $cachedRight;
            $cachedRight = $cachedLeft;
            $left = pop @lefts;
            $cachedLeft = pop @cachedLefts;
        }
        else {
            # Move right
            my $cachedNext = $taxonomy->lca($right, $rights->[0]);
            if ($taxonomy->rank($cachedRight) < $taxonomy->rank($cachedNext)) {
                push(@lefts, $left);
                push(@cachedLefts, $cachedLeft);
                $left = $right;
                $cachedLeft = $cachedRight;
                $right = shift @{$rights};
                $cachedRight = $cachedNext;
            }
            else {
                &$merge();
                if (@lefts) {
                    $right = $cachedRight;
                    $cachedRight = $cachedLeft;
                    $left = pop @lefts;
                    $cachedLeft = pop @cachedLefts;
                }
                else {
                    $left = $cachedRight;
                    $cachedLeft = $cachedRight;
                    $right = shift @{$rights};
                    $cachedRight = $cachedNext;
                }
            }
        }
    }
    &$merge();

    return \%numDescMatches;
}

sub penaltyScore {
    my ($taxonomy, $qVal, $totalMatches, $numMatches,$matrix) = @_;
    my @sorted = keys %{$numMatches};
    return (0, []) if (!@sorted);

    my @best = ();
    my $currVal;
    my $bestVal=10000000000000000000000000000000000000000000000000000000000;
    while (@sorted) {
	my $curr = shift @sorted;
	#print "- $curr ? \t";
	my $lineage = Taxonomy::getLineage($taxonomy, $curr);
	#print  join (';', map {$taxonomy->nodeInfo($_)} @{$lineage}),"\n";


	my $tp = $numMatches->{$curr};
        my $fp = $taxonomy->numDescLeaves($curr) - $tp;
        my $fn = $totalMatches - $tp;
	my $Recall=($tp/($tp+$fn));


	my $RecallThreshold=0.5;
	my $currVal = $qVal * ($fn / $tp) + (1 - $qVal) * ($fp / $tp);
	#print "( ".$Recall." / ".$currVal." )";


	if($Recall>$RecallThreshold) {
	    #print " [accepted] -> ( ".$Recall." / ".$currVal." ) ";
	    my $name = $fn.'_'.$tp.'_'.$fp;
	    $currVal = $matrix->{$name};

	    if(! defined($currVal)) {
		$currVal = $qVal * ($fn / $tp) + (1 - $qVal) * ($fp / $tp);
		$matrix->{$name} = $currVal;
	    }

	    if($currVal == $bestVal) {
		push(@best, $curr);
	    }
	    elsif ($currVal < $bestVal) {
		@best = ($curr);
		$bestVal = $currVal;
	    }
	}
	else {
	    #print "[rejected]\n";
	}
	#print "\n";
    }

    #print "Best val =  $bestVal \n";
    #foreach my $k (@best)  {
    #print "-> $k \n";
    #}
    return ($bestVal, \@best);
}

# Given a preprocessed taxonomy, compute the taxonomic assignment of @{$matches}.
sub assign {
    my ($taxonomy, $qVal, $read, $matches,$mat) = @_;
    my %numDescMatches = ();
    for my $m (@{$matches}) {
	$numDescMatches{$m} = 1;
    }
    my $skel = skeletonTree($taxonomy, \%numDescMatches);
    return penaltyScore($taxonomy, $qVal, scalar(@{$matches}), $skel, \%{$mat});
}


sub printResultSingle {
	my ($taxonomy, $read, $leaf,$outHandle) = @_;
	my $lineage = Taxonomy::getLineage($taxonomy, $leaf);
	print $outHandle "$read\tNONE\t", join (';', map {$taxonomy->nodeInfo($_)} @{$lineage}), "\n";
}

sub printResult {
	my ($taxonomy, $read, $value, $assignments, $outHandle) = @_;
	my $leaf;

	#Check if the assignment is unique
	if ((scalar @{$assignments}) == 1) {
	    $leaf = shift @{$assignments};
	    #print "One res -> $leaf \n";
	}
	else{
	    #print "multiple res \n";
	    #If it is not unique select the one(s) with lower rank (higher assigned number)
	    my $minRank = shift @{$assignments};
	    my @min_assign = ($minRank);
	    foreach my $k (@{$assignments}){
		if ($taxonomy->rank($k) > $taxonomy->rank($minRank)) {
		    $minRank = $k;
		    @min_assign = ($k);
		}
		elsif ($taxonomy->rank($k) == $taxonomy->rank($minRank)) {
		    push (@min_assign, $k);
		}
	    }
	    #Select randomly among the equal rank assignments
	    $leaf = $min_assign[ rand @min_assign ];
	}
	#Construct the lineage of the selected assignment
	my $lineage = Taxonomy::getLineage($taxonomy, $leaf);
	#Print the result
	print $outHandle "$read\t$value\t", join (';', map {$taxonomy->nodeInfo($_)} @{$lineage}), "\n";
}

1;
