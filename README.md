# FANCy: Functional Analysis of fuNgal Communities

## WAVES branch

This branch has a modified version of the pipeline designed to work with the LIRMM lab's WAVES web interface for bioinformatics commandline utilities project.


## Introduction

by: Katarzyna B. Hooks, Peter Bock, Laurence Delhaes, David Fitzpatrick, Macha Nikolski, Marin Fierens

The FANCy pipeline uses ITS1/ITS2 sequencing results and a reference ITS database to predict the fungal species composition in a community, then combines that information with the available functional annotation of the fungal genomes and using ancestral state reconstruction to summarise the gene families and pathways present in each sample.

It then uses R to perform several differential analysis of the pathways, comparing them between sample groups defined by the user, to determine which ones have a significant variance between groups.

This information is summarised in the form of a Pathways Abundance file containing the abundances of the different pathways for each sample, a file containing the statistical results (Pvalue, corrected Pvalue, log corrected values) as well as a PCA graph of the entire dataset and, if significant pathways for the user's chosen Pvalue cut-off were found, a heatmap showing their distribution across samples and values.


## Installation

Example commands for the installation are given for CentOS.

0. Clone the pipeline onto your local computer/cluster:

We clone directly from this repo, but you might want to clone from a forked copy on your own github account, in case you want to modify the pipeline later.

 ```shell
 yum install git
 
 mkdir pipeline
 
 cd pipeline
 
 git clone https://github.com/cbib/FANCy.git
 
 
 ```


1. Update your package installer (Yum for centOS, apt-get for ubuntu...)

```shell
yum update
```

2. Install Python3, pip3, setuptools and associated libraries.

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

It might also be necessary to install pip2, if it isn't installed by default, as both pip2 and 3 are needed.


3. Install Snakemake from source for the latest version:

jsonschema was a missing dependency for snakemake in our case, examining any error messages thrown during setup will allow you to determine if your system is missing any other dependencies.

```shell
git clone https://bitbucket.org/snakemake/snakemake.git

cd snakemake

pip3 install jsonschema

python3 setup.py install
```

4. Install R, as well as any dependencies our R libraries will need:

```shell
sudo yum install epel-release

sudo yum install R

sudo yum install libxml2-devel

yum install perl-Switch

yum install perl-core

```

5. Install the R libraries that our pipeline needs:

```shell
Rscript installLibraries.R
```
If you  already had an install of R on your machine, you might encounter error messags about other libraries having been compiled for different versions and being incompatible. normally re-installing these R libraries using install.packages() is enough to fix this problem.

6. Install any extra libraries needed by the pipeline:

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



7. Install the Castor R library using the pre-made script

```shell
Rscript scripts/install_castor.r
```

8. Install ete2 (python2 version)

```shell

pip2 install ete2

```
9. instal Picrust2

This step has an added complexity, as Picrust 2 is still in beta and has a few bugs in their installation script to take care of.

first install it's dependencies, Numpy, H5py, joblib and Biom-format (in that order).

Then use the included picrust2 installation script.

```shell
pip3 install numpy h5py joblib
pip3 install biom-format

python3 picrust2/setup.py install
```
The added complexity comes from Picrust2 not copying over folders, or content of said folders, into it's installation path.
Depending on where you installed it (here it was installed into the default python3.5 package location) you'll need to adapt the below command slightly:

```shell
cp -r picrust2/picrust2/Rscripts/ /usr/local/lib/python3.5/site-packages/PICRUSt2-2.0.0b3-py3.5.egg/picrust2/Rscripts
```
