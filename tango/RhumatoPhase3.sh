#! /bin/bash

MATCH_PATH="/mnt/cbib/Rhumato/GEM/Phase3/"
TAX_FILE="/mnt/data/AB/TANGO/NewVersion3/tango/GREEN_COMPLETE.prep"

# Test si on a une argument
if [ -z $1 ]
then
   echo "choose a sample"
   exit
fi




# Test sur le match file
QUI=$1;
MATCH_FILE=$MATCH_PATH$QUI".match"
OUT_FILE="/mnt/data/AB/TANGO/NewVersion3/tango/"$QUI
echo $MATCH_FILE
if [ -f $MATCH_FILE ]
then
    echo "Match file [FOUND]"
else 
    echo "No match file "$MATCH_FILE" found"
    exit
fi



# se mettre dans le bon répertoire
CMD_PATH="cd /mnt/data/AB/TANGO/NewVersion3/tango/"
$CMD_PATH



# Faire la boucle
for ((i=0 ; 10 - $i ; i++))
    do echo "--- "$i" ---"
    CMD="perl tango.pl --taxonomy "$TAX_FILE" --output "$OUT_FILE" --matches "$MATCH_FILE" --q 0."$i
    echo $CMD;
    $CMD
done

i=1
echo "--- "$i" ---"
CMD="perl tango.pl --taxonomy "$TAX_FILE" --output "$OUT_FILE" --matches "$MATCH_FILE" --q "$i 
echo $CMD;  
$CMD