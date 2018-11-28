from helpers import *
from subprocess import check_output
import sys
import csv
import glob
import pickle

def build_ko_matrix(nodes):
    mat = {}
    for kofilename in glob.glob('data/ko/*.tab'): # Searching in tab separated ko matrices
        parse_komat_file(kofilename,mat,nodes) # Parsing each file
    kos = write_komat('data/tmp/komat.tab',mat) # Writing matrix
    return (mat,kos)

def run_castor(this_path,output_dir):
    # Runs castor
    check_output(['python3',
        this_path + 'picrust2/scripts/hsp.py', # Picrust2 hsp.py script
        '-t', this_path + 'data/tmp/matchtree.txt', # Taxonomic tree
        '-o', this_path + output_dir + '/hsp', # Output file      replaced "+ '/' +"  with "+"
        '--observed_trait_table', this_path + 'data/tmp/komat.tab']) # KO matrix
    # Interpret castor
    f = open(output_dir + '/hsp.tsv')
    # Parsing header
    header = f.next().split('\t') # Array containing indexed ko names
    values = [data.split('\t') for data in f] # Array of arrays containing ko predictions for a species
    return (header,values)





def merge_ko_matrix_with_predictions(mat,values,header):
    for pred in values: # Parcouring predictions
        tax_id = pred[0]
        for ko_pred_it in range(1,len(pred)): # Parcouring kos
            merge_with_dict(mat,int(tax_id),header[ko_pred_it],int(pred[ko_pred_it]))











if len(sys.argv) == 4:
        cur_dir = sys.argv[1]
        output_dir = sys.argv[2]
        log_dir = sys.argv[3]

        # get the nodes produced by the Tango processing step.
        nodes = []
        with open(log_dir + "nodes.txt") as nodeFile:
            nodes = csv.reader(nodeFile)
            nodes = [int(item[0]) for item in nodes]
        print('<> Building ko matrix <>')
        mat, kos = build_ko_matrix(set(nodes))
        print('>>> Found ko for {} nodes ({} unique ko)'.format(str(len(mat)),str(len(kos))))


        print('<> Running castor for hidden state prediction <>')
        header, values = run_castor(cur_dir,output_dir)
        print('>>> Predicted state for {} leaves'.format(str(len(values))))


        print("<> Merging Castor predictions with KO matrix <>")
        merge_ko_matrix_with_predictions(mat,values,header)
        print(">>> Merge finished.")

        with open(output_dir + "/ko_merged.pickle", "w+") as dictFile:
            pickle.dump(mat,dictFile)







else:
        print "\n\nError in castor_predict arguments:"
        print "There should be 2 command line arguments (current_dir, output_dir)"
        print "Example:"
        print "python castor_predict.py /current/dir /output/dir"
