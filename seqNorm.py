import math
import sys
import pickle

# this script normalize the counts/sample data according to the users choice:

# 1. No normalization
# 2. Normalize by TSS (Total Sum Scaling, AKA., by scaling according to
# total sum of each sample)
# 3. Normalize by UQS (Upper Quartile Scaling, AKA., by scaling according to
# the upper quartile of each sample)

def upperQuartile(nums):


    nums.sort()
    high_mid = ( len( nums ) - 1 ) * 0.75 # 3rd / Upper quartile.


    ceil = int( math.ceil( high_mid ) )

    floor = int( math.floor( high_mid ) )


    uq = ( nums[ ceil ] + nums[ floor ] ) / 2.0



    return(uq)


def tss(dico):
    #apply Total Sum Scaling to a dataset
    ts = sum(dico.values())
    for key in dico.keys():
        if dico[key] != 0:
            dico[key] = dico[key] / float(ts)
    return(dico)


def uqs(dico):
    # apply Upper Quartile Scaling to a dataset
    uq = upperQuartile(dico.values())

    for key in dico.keys():
        if dico[key] != 0:
            dico[key] = dico[key] / float(uq)
    return(dico)

def datasetTSS(dataset):
    #apply TSS to every sample in a dataset
    for sample in dataset:
        dataset[sample] = tss(dataset[sample])
    return(dataset)

def datasetUQS(dataset):
    #apply UQS to every sample in a dataset
    for sample in dataset:
        dataset[sample] = uqs(dataset[sample])
    return(dataset)

#nums = {"A":{"a":10,"b":5,"c":15, "d":100}, "B": {"a":9, "b":18, "c":0}} #< Fill list with values

#print(datasetUQS(nums))
#print(datasetTSS(nums))




if len(sys.argv) == 3:
        output_dir = sys.argv[1]
        option = sys.argv[2]

        if option == "tss":
            with open(output_dir + "tps.pickle", "r") as dictFile:
                tps = pickle.load(dictFile)
            tps = datasetTSS(tps)
            with open(output_dir + "tps.pickle", "w") as dictFile:
                pickle.dump(tps,dictFile)
        elif option == "uqs":
            with open(output_dir + "tps.pickle", "r") as dictFile:
                tps = pickle.load(dictFile)
            tps = datasetUQS(tps)
            with open(output_dir + "tps.pickle", "w") as dictFile:
                pickle.dump(tps,dictFile)
        else:
            pass



else:
        print "\n\nError in seqNorm.py arguments:"
        print "There should be 2 command line arguments (output/dir/path and normalization option)"
        print "Examples:"
        print "python seqNorm.py /path/to/output/dir tss"
        print "python seqNorm.py /path/to/output/dir uqs"
        print "python seqNorm.py /path/to/output/dir none"
