import sys
from helpers import *
import csv
import pickle





def normalize_matrice_by_ITS(tps_mat,its_mat):
    matCopy = tps_mat

    for sample in matCopy:
        for taxonid in matCopy[sample]:
            # divide the species abundance by the ITS copynumber
            # given the ITS copynumber represents the number of ITS for that species/taxonid, and that normally
            # that number corresponds to a duplication ratio of sorts that must be corrected.
            if taxonid in its_mat.keys():
                matCopy[sample][taxonid] /= its_mat[taxonid]
            else:
                print("\nITS_mat does not contain this species/taxonid, its ITS copynumber value assumed to be 1\n")
    return matCopy


# Generate Ko / sample matrice
# by multiplying and summing taxonId / Sample (tps) and Ko / Taxonid (mat) matrices.
# Logic:
# for every ko, multiply it's abundance across all species present in a sample, to get the total number of that ko in that specific sample

def koSample_mat(tps,ko_mat):
    # First, generate the empty matrix with the KO's present in each sample.
    # An empty set to gather the unique ko's present in each sample
    koset = set()
    # matrix to hold the kos per sample information.
    sample_kos = dict()
    total = 0
    notFound = []
    for sample in tps:
        for taxon in tps[sample]:
            total += 1
            if taxon in ko_mat:
                # for each taxon in the sample, find it's associated KO's in the KO/taxon matrice.
                koset |= set(ko_mat[taxon].keys())
            else:
                #print("not in DB")
                notFound.append(taxon)
        sample_kos[sample] = {key : 0 for key in list(koset)}
        koset = set()

    # now, fill the empty matrix by summing the kos present in the different samples using the tps and mat matrices.
    print("There were {} taxons out of {} that weren't in the KO matrix but were present in the samples.".format(len(notFound),total))
    # initialize the total KO value at 0
    koval = 0


    missingTaxons = set()
    # for each sample in the KOSample matrix we just created
    for sample in sample_kos:

        for ko in sample_kos[sample]:

            # for all the taxonids present in that sample
            for taxonid in tps[sample]:
                # if a KO from the KO/sample matrix is present in the KO/taxon matrix
                try:
                    if ko in ko_mat[taxonid]:
                        # get the normalized value from Taxon/sample
                        tpsNorm = tps[sample][taxonid]
                        # get the non-normalized value from KO/Taxon
                        matVal = ko_mat[taxonid][ko]
                        # multiply the KO's abundance value in the taxon by the abundance of that taxon in the sample
                        # add it to the sum of that KOs values, for all taxonids in that sample
                        koval += tpsNorm * matVal
                except:
                    missingTaxons.add(taxonid)
            # add the total sum of that KO's products for that sample to the kos/sample matrix
            sample_kos[sample][ko] = koval
            # reset koval to 0 for the next KO's sum to be calculated.
            koval = 0
            # the missingTaxons identifies the taxons present in tps but not in the Castor predictions(mat). if there are too
            # many it might be problematic.
    return(sample_kos)

















if len(sys.argv) == 4:
        cur_dir = sys.argv[1]
        output_dir = sys.argv[2]
        log_dir = sys.argv[3]

        with open(output_dir + "ko_merged.pickle", "r") as dictFile:
             mat = pickle.load(dictFile)

        with open(output_dir + "tps.pickle", "r") as dictFile:
             tps = pickle.load(dictFile)


        with open(log_dir  + "ids.txt", "r") as idFile:
            ids = csv.reader(idFile)
            ids = [int(item[0]) for item in ids]



            
        # write ITSCopyNumber data: (Temporary measure writing 1 for all species)

        its_mat = its_table(ids)

        write_dict(output_dir + 'ITS_copynums.tab',its_mat)

        # Normalize by ITSNumber / species for the *Species abundance by Sample* (tps)  matrice of data.

        tps = normalize_matrice_by_ITS(tps,its_mat)



        # fill the Ko / sample (final result matrice)
        # by multiplying and summing taxonId / Sample (tps) and Ko / Taxonid (mat) matrices.

        ko_sample_mat = koSample_mat(tps,mat)

        # write the ko-by-sample matrix used as input to minpath to a file

        write_doubledict(output_dir + '/KO_by_sample_normalized.tsv',ko_sample_mat)







else:
        print "\n\nError in castor_predict arguments:"
        print "There should be 2 command line arguments (current_dir, output_dir)"
        print "Example:"
        print "python castor_predict.py /current/dir /output/dir"
