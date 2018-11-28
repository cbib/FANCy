#! /usr/bin/env bash

./preprocess.pl --taxonomy-type greengenes --taxonomy Greengenes.taxa --output GREEN.prep

./convertTaxonomy.pl --original-type greengenes --final-type greengenes --taxonomy Greengenes.taxa --mapping none --output GREEN2GREEN.ser