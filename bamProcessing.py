import os
import sys
import glob
import re
import subprocess
import copy
import csv

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
        if(".sam.sam" in sam):
                sam = sam.replace(".sam.sam",".sam")
        if not os.path.isdir('matchfiles'):
                os.mkdir('matchfiles')
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

def bamtosam(bam):
        if checkIntegrity(bam):
                return "Error: integrity check failed for file {}, not a proper bam file or contains errors.".format(bam)
        samName = bam.replace(".bam", ".sam")
        subprocess.call(["samtools", "view", "-h", "-o", samName, bam])

        return samName

def bamProcessing(bamDir,matchDir):
        ## if BAM, then do the BAM steps using the commandline arguments Directory,
        # being a directory containing the bam files.
	# create the sam file for the current bam, then process it as usual. (see writeMatch function)
        for bam in glob.glob(bamDir + "/*.bam"):
            sam = bamtosam(bam)
            match = readSam(sam, {})
            writeMatch(matchDir + "/" + sam.split("/")[-1], match)
            subprocess.call(["rm", sam])



##################Main############################

# if script called with 3 arguments (script, BAMdir and matchDir) then apply the BAM processing path
if len(sys.argv) == 4:
        bamdir = sys.argv[1]
        matchdir = sys.argv[2]
        allowed=int(sys.argv[3])
        
        bamProcessing(bamdir, matchdir)
        
        # count number of files that were in the ZIP. Our pipeline is limited to a total of 30 copies
        onlyfiles = next(os.walk(bamdir))[2] #dir is your directory path as string
        
        if len(onlyfiles) > allowed:
            print("The total number of Sample files exceeds the allowed number for our web interface (" + str(allowed) + "),\neither cut down on the number of sample files (entries in you BAM zip file) or install the local version of this pipeline:\n\t https://github.com/cbib/FANCy\n")
            sys.exit(1)

else:
        print("\n\nError in bamProcessing.py arguments:")
        print("There should be 3 command line arguments (the bamfiles directory and the output match directory, as well as the total allowed number of samples)")
        print("Example:")
        print("python bamProcessing.py /path/to/BAMfile/dir /path/for/output/matchfiles allowed-sample-num")
