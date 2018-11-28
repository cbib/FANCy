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
	
	$filepath=$dirname.$filename;
	print "Treat $filepath \n";
	
	$PBSfile="PBS050/".$filename.".pbs";
	$outfile="PBS050/".$filename;	
        print $PBSfile."\n";
	open(W3,">".$PBSfile);
	print W3 "#PBS -S /bin/bash  \n";
	print W3 "#PBS -N TANGO_".$filename."  \n";
	print W3 "#PBS -M abarre-bordeaux2.fr   \n";
	print W3 "#PBS -l nodes=1   \n";
	print W3 "#PBS -l walltime=128:00:00   \n";
	print W3 "#PBS -e /mnt/data/AB/TANGO/GoodVersion/tango_filter_recall/PBS050/".$filename.".err   \n";
	print W3 "#PBS -o /mnt/data/AB/TANGO/GoodVersion/tango_filter_recall/PBS050/".$filename.".out   \n";
	print W3 "cd /mnt/data/AB/TANGO/GoodVersion/tango_filter_recall/  \n";
	print W3 "perl tango.pl --taxonomy GREEN_COMPLETE.prep --matches $filepath  --q-value 0.5 --output $outfile \n";
	close(W3);

	`qsub $PBSfile`;
	sleep(1);
    }
}
closedir(DIR);


