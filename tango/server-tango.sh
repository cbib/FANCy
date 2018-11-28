#! /usr/bin/env bash

echo "Convert matches..."
echo "N2N"
./convertMatches.pl --matches $TEST/sample.match --mapping $TEST/NCBI2NCBI.ser --output $TEST/sampleN2N.match
echo "R2R"
./convertMatches.pl --matches $TEST/sample.match --mapping $TEST/RDP2RDP.ser --output $TEST/sampleR2R.match
echo "G2G"
./convertMatches.pl --matches $TEST/sample.match --mapping $TEST/GREEN2GREEN.ser --output $TEST/sampleG2G.match
echo "Done."

Q="--q-value 1"

echo "Testing TANGO..."
echo "N2N"
./tango.pl --taxonomy $TEST/NCBI.prep --matches $TEST/sampleN2N.match --output $TEST/N2N.res $Q
echo "R2R"
./tango.pl --taxonomy $TEST/RDP.prep --matches $TEST/sampleR2R.match --output $TEST/R2R.res $Q
echo "G2G"
./tango.pl --taxonomy $TEST/GREEN.prep --matches $TEST/sampleG2G.match --output $TEST/G2G.res $Q
echo "Done."