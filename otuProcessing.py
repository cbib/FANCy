import sys
import glob
import re
import subprocess
import copy
import csv
from os import path,makedirs

#requires samtools to be installed and in System Path.


##################Functions############################

def checkIntegrity(filePath):
        # checks if the SAM or BAM file
        # has the proper header and EOF components
        # 0 --> All good
        # 1 or other --> problem, abort pipeline or ignore file ?
        return subprocess.call(["samtools", "quickcheck", filePath])




def readSam(samFile, matchDict):
        copyDict = copy.deepcopy(matchDict) # shallow copying is a nightmare XO
        print("sam -> match for {}".format(samFile))
        with open(samFile,"r") as data:
                for line in data.readlines():
                        amper = re.search('^[^\@]', line)

                        if amper:
                                elements = line.split("\t")


                                if elements[2] != "*":

                                        if elements[0] not in copyDict:
                                                copyDict[elements[0]] = {}
                                        if elements[2] in copyDict[elements[0]]:
                                                copyDict[elements[0]][elements[2]] += 1
                                        else:
                                                copyDict[elements[0]][elements[2]] = 1
        return(copyDict)

def writeMatch(sam, link, repeats = {}):
        with open(sam + ".match", "w+") as matchFile:

                for key1 in link.keys():
                        line = ""
                        if key1 in repeats.keys():
                                n = repeats[key1]
                        else:
                                n = 1
                        line += key1
                        for key2 in link[key1].keys():
                                line += " " + key2
                        for i in range(0,n):
                                matchFile.write(line + "\n")

def otuTableProcessor(otuTablePath):
        # separates the OTU/Sample values into different dictionaries per sample, {sample1: {...}, sample2:{...}}
        # each containing the otu and their repeat numbers. {otu1 : 1, otu2: 5 ...}
        otuDict = {}
        with open(otuTablePath, "r") as otuFile:
                reader = csv.DictReader(otuFile, delimiter = "\t")

                for otuValues in reader:
                        otuName = otuValues["otu"]
                        sampleNames = otuValues.keys()
                        sampleNames.remove("otu")
                        for sample in sampleNames:
                                if sample not in otuDict:
                                        otuDict[sample] = {}
                                otuDict[sample][otuName] = int(otuValues[sample])

        return(otuDict)




def otuProcessing(otuSeqPath, otuTablePath, matchDir):
	## do the OTU steps using the commandline arguments Directory, OtuTable and OtuSequences.
	# then use BWA to make a sam file from the OTU sequence file.
	# with this samfile and the OTU table giving the OTU copies per sample,
	# generate individual matchfiles for each sample, using the number of times an OTU is present in a sample to
	# determine how many times said OTU's line should be printed in the matchfile.

        # map the OTU Sequence file using our UNITEid DB (pre-indexed using "bwa index")
        sam = otuSeqPath + ".sam"
        checkIntegrity(sam)
        with open(sam, "w") as samFile:
                subprocess.call(["bwa", "mem", "-a", "./UNITEid", otuSeqPath], stdout=samFile)

        otuPerSample = otuTableProcessor(otuTablePath)

        samData = readSam(sam, {})

        for sample in otuPerSample:
                matchfileName = matchDir + "/" + sample + ".sam"
                writeMatch(matchfileName,samData,otuPerSample[sample])


##################Main############################

#if 4 arguments (script, OTUSeqPath, OtuTablePath and matchDIR)
if len(sys.argv) == 4:
        otuseq = sys.argv[1]
        otutable = sys.argv[2]
        matchdir = sys.argv[3]
        if not path.isdir(matchdir):
            makedirs(matchdir)
        otuProcessing(otuseq, otutable, matchdir)
else:
        print "\n\nError in makeMatch.py arguments:"
        print "There should be 3 command line arguments (Path to OTUsequence file, Path to OTU/sample table, and output Match directory)"
        print "Example:"
        print "python makeMatch.py /Path/to/OTUSequenceFile /Path/to/OTUperSampleFile /Path/for/output/matchfiles"
