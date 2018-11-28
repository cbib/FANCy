#!/usr/bin/perl
use Getopt::Long;

my $getter = GetOptions ("dir=s" => \$dirname,
			 "help" => \$help);


# The directory
if(! -d $dirname) {
    print "[ERROR] $dir not found ! \n";
    exit;
}

if($dirname =~ /[^\/]+$/) {
    $dirname.="/";
}



# Explore directory to find match files
@FILES=();
opendir ( DIR, $dirname ) || die "Error in opening dir $dirname\n";
while( ($filename = readdir(DIR))){
    if($filename =~ /\.match$/) {
	push(@FILES,$filename);
    }
}
closedir(DIR);





# Analayse each match file
foreach $f (@FILES) {
    
    $matchFile=$dirname.$f;
    $OneMatch=0;
    $MultiMatch=0;

    open(my $matchHandle, $matchFile) || die "Could not open $matchFile.\n";
    while (<$matchHandle>) {
	my @matches = split(" ", $_);
	my $read = shift @matches;
	
	if(scalar(@matches)==1) {
	    $OneMatch++;
	}
	else {
	    $MultiMatch++;
	}
	
    }
    close($matchHandle);
    
    $OneMatchPC=($OneMatch*100)/($OneMatch+$MultiMatch);
    $MultiMatchPC=($MultiMatch*100)/($OneMatch+$MultiMatch);
    print $f." : ".$OneMatch."(".$OneMatchPC.")| ".$MultiMatch." (".$MultiMatchPC.")\n";
}
