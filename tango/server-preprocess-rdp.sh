#! /usr/bin/env bash

./preprocess.pl --taxonomy-type rdp --taxonomy RDP.taxa --output RDP.prep

./convertTaxonomy.pl --original-type rdp --final-type rdp --taxonomy RDP.taxa --mapping none --output RDP2RDP.ser