# FANCy: Functional Analysis of fuNgal Communities

## Introduction

by: Katarzyna B. Hooks, Peter Bock, Laurence Delhaes, David Fitzpatrick, Macha Nikolski, Marin Fierens

The FANCy pipeline uses ITS1/ITS2 sequencing results and a reference ITS database to predict the fungal species composition in a community, then combines that information with the available functional annotation of the fungal genomes and using ancestral state reconstruction to summarise the gene families and pathways present in each sample.

It then uses R to perform several differential analysis of the pathways, comparing them between sample groups defined by the user, to determine which ones have a significant variance between groups.

This information is summarised in the form of a Pathways Abundance file containing the abundances of the different pathways for each sample, a file containing the statistical results (Pvalue, corrected Pvalue, log corrected values) as well as a PCA graph of the entire dataset and, if significant pathways for the user's chosen Pvalue cut-off were found, a heatmap showing their distribution across samples and values.


## Installation
