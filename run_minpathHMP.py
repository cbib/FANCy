import pandas
import sys
from minpath_functions import *
from os import path,makedirs


# Generate the directory structure then launch MinPathHMP on the KO/Sample matrice.
# When that is done, return the output to the calling function/program/script

def minPathHMP(inputfile,outputDir,currentdir):
    minpathDir = outputDir + "/minpath_results"

    if not os.path.exists(minpathDir):
        makedirs(minpathDir)


    results = run_minpath_pipeline(inputfile,
                                   currentdir,
                                   proc=1,
                                   out_dir=minpathDir,
                                   print_cmds=False)

    return(results)



if len(sys.argv) == 3:
        cur_dir = sys.argv[1]
        output_dir = sys.argv[2]

        # Execute the MinPath segment of the pipeline
        ko_by_sample = output_dir + '/KO_by_sample_normalized.tsv'

        # reads in a Pandas structure with the pathway abundances by sample:

        pathway_abundances = minPathHMP(ko_by_sample, output_dir,cur_dir)


        pathway_abundances.to_csv(output_dir + '/pathwayAbundances.csv')







else:
        print "\n\nError in castor_predict arguments:"
        print "There should be 2 command line arguments (current_dir, output_dir)"
        print "Example:"
        print "python castor_predict.py /current/dir /output/dir"
