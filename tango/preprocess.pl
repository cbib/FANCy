#! /usr/bin/env perl
use Getopt::Long;
use Switch;
use strict;
use GREENGENES;
use NCBI;
use RDP;
use UNITE;


my $taxType;
my $taxFile;
my $outFile;
my $contract;

my $getter = GetOptions ("taxonomy-type=s" => \$taxType,
			 "taxonomy=s"   => \$taxFile,
			 "output=s"  => \$outFile,
                         "contract" => \$contract);



# Test mandatory parameters
my @all_params=($taxType,$taxFile,$outFile);
foreach my $param (@all_params) {
    if(!$param || $param eq "") {
	&usage();
    }
}

# test Taxonomy name
my $TaxonomyName=&TaxonomyTypeExist($taxType);


# Construct taxonomy object
my $taxonomy;
print "Treating ".$TaxonomyName." file \n";
switch ($TaxonomyName) {
    case "GREENGENES"	{
	$taxonomy = GREENGENES->new($taxFile);
    }
    case "NCBI"	{
	$taxonomy = NCBI->new($taxFile);
    }
    case "RDP"	{
	$taxonomy = RDP->new($taxFile);
    }
		case "UNITE" {
	$taxonomy = UNITE->new($taxFile);
		}
    else {
	print "Error ! \n"; exit;
    }
}


# Contract option
if($contract)  {
    my $contracted = $taxonomy->contract();
    $contracted->serialize($outFile);
}
else {
    $taxonomy->serialize($outFile);
}

print "Completed ! \n\n";












########## functions ############


sub usage {
    print "Usage: perl preprocess.pl --taxonomy-type <taxonomy_type> --taxonomy <taxonomy_file> --output <output_file> --contract\n";
    print "\t<taxonomy_type>:  see TaxonomyList file \n";
    print "\t<taxonomy_file>:\n";
    print "\t\tGreengenes: http://greengenes.lbl.gov/Download/Sequence_Data/Fasta_data_files/current_GREENGENES_gg16S_unaligned.fasta.gz\n";
    print "\t\tRDP: http://rdp.cme.msu.edu/misc/resources.jsp (Genbank, combined, unaligned).\n";
    print "\t\t\tE.g.: http://rdp.cme.msu.edu/download/release10_29_unaligned.gb.gz\n";
    print "\t\tNCBI: ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz, file \"nodes.dmp\".\n";
    print "\t<output_file>: destination of the preprocessed taxonomy.\n";
    print "\t--contract if you want to contract the taxonomy \n";
    exit;
}


sub TaxonomyTypeExist {
    my $ThisType=shift;
    my $ResGrep=`grep -i $ThisType ./TaxonomyList`;
    $ResGrep=~s/\n//;
    if($ResGrep eq "") {
	print "Unknown toxonomy type '$ThisType' ! \n";
	print "See the TaxonomyList file \n";
	exit;
    }
    else {
	return uc($ResGrep);
    }
}
