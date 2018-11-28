#! /usr/bin/env bash

./preprocess.pl --taxonomy-type ncbi --taxonomy NCBI_taxdump.tar.gz --output NCBI.prep

./convertTaxonomy.pl --original-type ncbi --final-type ncbi --taxonomy NCBI_nodes.dmp --mapping none --output NCBI2NCBI.ser --ncbi-merged NCBI_merged.dmp --ncbi-deleted NCBI_delnodes.dmp