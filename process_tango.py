import glob
import sys
from ete3 import NCBITaxa
from os import path,makedirs
from helpers import *
import pickle

# helpers is in pipeline/lib/helpers.py, so thi script needs to be moved to /lib/ too

# Process the tango results, use them to build the Taxonomy tree then save
# the resulting information in files for the next step of the pipeline.


# Parses a tango file line by line
def explore_tango_file(ncbi,filename,allowed):
    with open(filename,'r') as file:
        for line in file:
            data = line.split('\t')
            if len(data) == 3: # Data has 3 tab separated parts (read id    score   taxon)
                if data[2][0] == 's': # Species
                    name = ' '.join(data[2].split('_')[1:]).strip('\n') # finds name of taxon
                    id = int(ncbi.get_name_translator([name]).get(name,[-1])[0]) # finds id from name (this api is weird)
                    yield ('s',id) if id != -1 else ('s',-1)
                elif data[2][0] in allowed: # Taxonomic group
                    name = data[2].split('_')[1].split(' ')[0]
                    id = int(ncbi.get_name_translator([name]).get(name,[-1])[0])
                    yield (data[2][0],id) if id != -1 else (data[2][0],-1)


# Parses tango results from output folder only for allowed taxonomic groups
# ids : Taxonomic id set of taxa found
# sps : Taxonomic id set of species found
# rpr : Dictionary counting how many times a taxonomic id appears in this sample
# tps : Taxons Per Sample -> Dict containing the rpr dicts for each sample
# err : Errors
def parse_tango_results(ncbi,output_dir,allowed = ['c','g','f','k','o','p']):
    ids, sps, rpr, tps, err = (set(), set(), dict(), dict(), [])
    for sample in glob.glob(output_dir + '/tango/*'):
        print('--- Loading {} ---'.format(sample))
        for (tax_group, tax_id) in explore_tango_file(ncbi,sample,allowed):
            if tax_id != -1:
                ids.add(tax_id)
                count_dict(rpr,tax_id)
                if tax_group == 's': # Species
                    sps.add(tax_id)
            else:
                err.append((tax_group,tax_id))
        if "/" in sample:
            sample = sample.split("/")[-1]
        tps[sample] = rpr
        # empty rpr so that it can be filled anew with the next samples taxon id count.
        rpr = dict()

    return (ids,sps,tps,err)

# Building tree from identified taxa

def build_tree(ncbi,ids):
    nodes = set(ids) # Set of all nodes of a tree containing all the taxons found from the root rank
    for id in ids:
        nodes.update(ncbi.get_lineage(id)) # Adding the direct lineage of each node to the node list
    tree = ncbi.get_topology(nodes) # ncbi api creates a taxonomic tree from all the nodes
    if not path.isdir("data/tmp"):
        makedirs("data/tmp")
    tree.write(format=1,outfile='data/tmp/matchtree.txt') # writing tree
    return nodes

# Log the taxa information in files in the log directory

def log_taxa(log_dir,this_path,ids,sps,nodes,tps):
    if not path.isdir(log_dir):
        makedirs(log_dir)
    write_list(log_dir + '/species.txt',sps)
    write_list(log_dir + '/ids.txt', ids)
    write_list(log_dir + '/nodes.txt',nodes)
    
    write_doubledict(log_dir + '/weights_by_sample.tsv',tps)



################################# MAIN #########################




if len(sys.argv) == 5:
        DIRECTORY = sys.argv[1]
        LOG_DIR = sys.argv[2]
        OUTPUT_DIR = sys.argv[3]
        SQLITE_LOC = sys.argv[4]


        ncbi = NCBITaxa(SQLITE_LOC)

        print('<> Parsing match results <>')
        ids, sps, tps, err = parse_tango_results(ncbi,OUTPUT_DIR)
        print('>>> Found {} unique matches ({} species)'.format(str(len(ids)),str(len(sps))))

        print('<> Building taxonomic tree <>')
        nodes = build_tree(ncbi,ids)
        print('>>> Tree has {} nodes'.format(str(len(nodes))))

        log_taxa(LOG_DIR,DIRECTORY,ids,sps,nodes,tps)
        with open(OUTPUT_DIR + "/tps.pickle", "wb+") as dictFile:
            pickle.dump(tps,dictFile)

	# Add Lineage-compliant species file:

        with open(LOG_DIR + "/weights_by_sample.tsv","r") as oldfile:
            with open(LOG_DIR + "/species_by_sample.tsv","w+") as newfile:
                oldHeader = str(oldfile.readline()).split("\t")
                oldHeader = "\t".join([id.split(".")[0] for id in oldHeader])


                header = "Taxon_Name\t" + str(oldHeader)
                newfile.write(header)
                for line in oldfile:
                    contents = line.split()
                    ID = int(contents[0])
        
                    lineageIDs = ncbi.get_lineage(ID)
                    names = ncbi.translate_to_names(lineageIDs)
                    if "Fungi" in names:
                        FungiLineage = names[names.index("Fungi"):]
                        lineage = ";".join(FungiLineage)
                    else:
                        lineage = print(";".join(names))

                    newfile.write(lineage + "\t" + line)



else:
        print("\n\nError in process_tango.py arguments:")
        print("There should be 4 command line arguments (path/to/main/dir /path/to/log/dir path/to/output/dir /path/to/sqlite/ncbi/db)")
        print("Example:")
        print("python process_tango.py /piepeline log/ out/ ncbiDB/sqlite.taxa")
