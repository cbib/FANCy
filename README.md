# FANCy: Functional Analysis of fuNgal Communities


## Introduction

by: Katarzyna B. Hooks, Peter Bock, Laurence Delhaes, David Fitzpatrick, Macha Nikolski, Marin Fierens

The FANCy pipeline uses ITS1/ITS2 sequencing results and a reference ITS database to predict the fungal species composition in a community, then combines that information with the available functional annotation of the fungal genomes and using ancestral state reconstruction to summarise the gene families and pathways present in each sample.

It then uses R to perform several differential analysis of the pathways, comparing them between sample groups defined by the user, to determine which ones have a significant variance between groups.

This information is summarised in the form of a Pathways Abundance file containing the abundances of the different pathways for each sample, a file containing the statistical results (Pvalue, corrected Pvalue, log corrected values) as well as a PCA graph of the entire dataset and, if significant pathways for the user's chosen Pvalue cut-off were found, a heatmap showing their distribution across samples and values.


## Installation

Example commands for the installation are given for a CentOS VM set up for this purpose.

* Clone the pipeline onto your local computer/cluster:

We clone directly from this repo, but you might want to clone from a forked copy on your own github account, in case you want to modify the pipeline later.

 ```shell
 yum install git
 
 mkdir pipeline
 
 cd pipeline
 
 git clone https://github.com/cbib/FANCy.git
 
 
 ```


* Update your package installer (Yum for centOS, apt-get for ubuntu...)

```shell
yum update
```

* Install Python3, pip3, setuptools and associated libraries.

This was done from source to get the latest versions (built-in repositories for Yum were outdated on CentOS)

```shell
sudo yum install yum-utils 

sudo yum-builddep python 

curl -O https://www.python.org/ftp/python/3.5.0/Python-3.5.0.tgz 

tar xf Python-3.5.0.tgz

cd Python-3.5.0

./configure

make

sudo make install 

```


* Install Snakemake from source for the latest version:

jsonschema was a missing dependency for snakemake in our case, examining any error messages thrown during setup will allow you to determine if your system is missing any other dependencies.

```shell
git clone https://bitbucket.org/snakemake/snakemake.git

cd snakemake

pip3 install jsonschema

python3 setup.py install
```

* Install R, as well as any dependencies our R libraries will need:

```shell
sudo yum install epel-release

sudo yum install R

sudo yum install libxml2-devel
```
* Install Perl and Perl Core libraries.

```
yum install perl-Switch

yum install perl-core

```

* Install any extra libraries needed by the pipeline:

```shell
pip2 install pandas


yum install wget

wget http://ftp.gnu.org/gnu/glpk/glpk-4.55.tar.gz

tar zxvf glpk-4.55.tar.gz

cd glpk-4.55

./configure

make

make install


yum install curl-devel

yum install R-Rcpp

```



* Install the Castor R library using the pre-made script

```shell
Rscript scripts/install_castor.r
```

* Install the R libraries that our pipeline needs:

```shell
Rscript installLibraries.R
```
If you  already had an install of R on your machine, you might encounter error messags about other libraries having been compiled for different versions and being incompatible. normally re-installing these R libraries using install.packages() is enough to fix this problem.

* Install ete2 (python2 version)

```shell

pip3 install ete3

```
* Picrust2

We opted not to install the entire Picrust2 pipeline, as it is in beta and the installation script was non-functional for our version.

Instead we got Python3 to be able to interprete the entire Picrust2 folder in our pipeline's directory as a local module, though this necessitated a syslink, although uploading to Github has transformed this into a simple directory containing the extra scripts.

This means that Picrust2 most likely won't work outside the limited usage of Castor and Minpath that we make of it in our pipeline.


## Using the Pipeline

The pipeline has 2 methods of execution.

### FANCy with BAM files

FANCy can be executed using a zip file containing a collection of bam files:


```shell
FANCy-bam.sh  bamZip matchfiles log out metadataVector pValue normMethod MetaGrp1 MetaGrp2
```

### FANCy with OTU table and fasta

FANCy can also be executed using a table of OTU sequences and their abundances in each sample, and a FASTA file containing the sequences for each of aforementioned OTU sequences.

```shell
FANCy-otu.sh otuTable.txt otuSeqs.fasta matchfiles log out metadataVector pValue normMethod MetaGrp1 MetaGrp2
```

#### Argument details:

|    Argument    |                                                                    Explanation                                                                   |
|:--------------:|:------------------------------------------------------------------------------------------------------------------------------------------------:|
|     bamZip     |      Zip file containing the BAM files to analyse.  name of zip file will be used as name of the directory that will contain the BAM files.      |
|    otuTable    |                File containing a comma-separated table of OTU sequences and their abundances in each sample (see example/otuTable)               |
|     otuSeqs    |                              File containing the Fasta sequences for each OTU in the OTU Table (see example/otuSeqs)                             |
|   matchfiles   |                           Directory that will store the Matchfiles (created if non-existent, overwrites existing files)                          |
|       log      |                              Directory that will store the logs (created if non-existent, overwrites existing files)                             |
|       out      |                             Directory that will store the output (created if non-existent, overwrites existing files)                            |
| MetadataVector |          CSV File containing the Metadata vector, with the group each sample belongs to (1 group per sample, see example/metadataVector)         |
|     pValue     | P Value for the statistical significance testing of the pathways (0.05 is the norm, impacts creation or not of the significant pathways heatmap) |
|   normMethod   |  Normalization method chosen to adjust for sequencing depth ("tss":Total Sum Scaling, "uqs":Upper Quartile Scaling, or none for any other input) |
| MetaGrp1       |                                First group of the metadata vector to examine statistical differential expression.                                |
| MetaGrp2       |                                second group of the metadata vector to examine statistical differential expression.                               |
