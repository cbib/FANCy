#!/usr/bin/perl

($name)=($ARGV[0] =~ /([^\/]+)$/);


# ANALYSE MATCH 
open(W1,">ONE.match");
open(W2,">MORE.match");
$matchFile=$ARGV[0];
open(my $matchHandle, $matchFile) || die "Could not open $matchFile.\n";
while (<$matchHandle>) {
    my @matches = split(" ", $_);
    my $read = shift @matches;

    if(scalar(@matches)==1) {
	print W1 $_;
    }
    else {
	print W2 $_;
    }

}
close($matchHandle);
close(W1);
close(W2);

# ALL FILE LIST
@ALLfiles=();

# SPLIT ONE FILE
@ONEfiles=();
`split -l 150000 ONE.match ONE_PART_`;
opendir ( DIR,"./") || die "Error in opening dir $dirname\n";
while( ($filename = readdir(DIR))){
    if($filename =~ /ONE\_PART\_/) {
	push(@ONEfiles,$filename);
	push(@ALLfiles,$filename);
    }
}
closedir(DIR);

# SPLIT MORE FILE
@MOREfiles=();
`split -l 30000 MORE.match MORE_PART_`;
opendir ( DIR,"./") || die "Error in opening dir $dirname\n";
while( ($filename = readdir(DIR))){
    if($filename =~ /MORE\_PART\_/) {
	push(@MOREfiles,$filename);
	push(@ALLfiles,$filename);
    }
}
closedir(DIR);


print "Launch ... \n";
%LineInFile=();


foreach $f (@ONEfiles) {
    $wc=`wc -l $f`;
    ($linenumber)=($wc =~ /^(\d+)/);
    $LineInFile{$f}=$linenumber;
    print " -> $f (".$linenumber.")\n";
    $PBSfile=$f.".pbs";
    open(W3,">".$PBSfile);
    print W3 "#PBS -S /bin/bash  \n";
    print W3 "#PBS -N TANGO_".$f."  \n";
    print W3 "#PBS -M abarre-bordeaux2.fr   \n";
    print W3 "#PBS -l nodes=1   \n";
    print W3 "#PBS -l walltime=72:00:00   \n";
    print W3 "#PBS -e /mnt/data/AB/TANGO/NewVersion3/tango/".$f.".err   \n";
    print W3 "#PBS -o /mnt/data/AB/TANGO/NewVersion3/tango/".$f.".out   \n";
    print W3 "cd /mnt/data/AB/TANGO/NewVersion3/tango  \n";
    print W3 "time perl tango.pl --taxonomy GREEN_COMPLETE.prep --matches $f  --q-value 0.5 --output $f  \n";
    close(W3);
    `qsub $PBSfile`;
    sleep(1);
    
}

foreach $f (@MOREfiles) {
    $wc=`wc -l $f`;
    ($linenumber)=($wc =~ /^(\d+)/);
    $LineInFile{$f}=$linenumber;
    print " -> $f (".$linenumber.")\n";
    $PBSfile=$f.".pbs";
    open(W3,">".$PBSfile);
    print W3 "#PBS -S /bin/bash  \n";
    print W3 "#PBS -N TANGO_".$f."  \n";
    print W3 "#PBS -M abarre-bordeaux2.fr   \n";
    print W3 "#PBS -l nodes=1   \n";
    print W3 "#PBS -l walltime=72:00:00   \n";
    print W3 "#PBS -e /mnt/data/AB/TANGO/NewVersion3/tango/".$f.".err   \n";
    print W3 "#PBS -o /mnt/data/AB/TANGO/NewVersion3/tango/".$f.".out   \n";
    print W3 "cd /mnt/data/AB/TANGO/NewVersion3/tango  \n";
    print W3 "time perl tango.pl --taxonomy GREEN_COMPLETE.prep --matches $f  --q-value 0.5 --output $f  \n";
    close(W3);
    `qsub $PBSfile`;
    sleep(1);
}

print "END ! \n";


print "Wait ";
$flag=0;
while($flag==0) {
    print ".";
    $qstat=`qstat`;
    if($qstat =~ /ONE\_PART/ || $qstat =~ /MORE\_PART/) {
	$flag=0;    
    }
    else {
	$flag=1;
    }
    sleep(1);
}
print "\n";



open(W,">>MPall.time");
print W $name."\n";
foreach $f (@ALLfiles) {
    print W $f." :";
    $firstval="";
    
    open(R,$f.".err");
    while(<R>) {
	if($_ =~ /^\w+/)  {
	    ($val)=($_ =~ /^\w+\s+([^\s]+)/);
	    print W $val." | ";
	    if($firstval eq "") {
		$firstval=$val;
	    }
	}
    }

    ($nbseconde,$nbmili)=($firstval =~ /m(\d+)\.(\d+)/);
    $tempsmin=1.6;
    $temps=($nbseconde+($nbmili/1000))-$tempsmin;
    $vitesse=$LineInFile{$f}/$temps;
    print W " | ".$LineInFile{$f}." lines / ".$temps." sec = $vitesse ";
    print W "\n";
    close(R);
}
close(W);

`rm ONE*`;
`rm MORE*`;
