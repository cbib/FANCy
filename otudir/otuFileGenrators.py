import random

fasta = []
rem = True

with open("SRR3206640.fastq", "r+") as fastq:
    for line in fastq:
        if set(line.strip()) == set(["A","T","C","G"]):
            fasta.append(line.strip())
        if len(fasta) > 3000:
            break



# now we have 149 separate sequences.
# write them to a OTUSequence.fasta file with identifiers otu(0-149)

otuNames = {">otu" + str(i): fasta[i] for i in range(len(fasta))}

with open("otuSeqs.fasta","w+") as otuSeq:
    for i in range(len(otuNames)):
        otuSeq.write(list(otuNames.keys())[i] +"\n")
        otuSeq.write(list(otuNames.values())[i] +"\n")
        
# now that we have that, we need to generate the .txt file
# containing tab-separated otu values for each otu and sample:

with open("otuTable.txt", "w+") as otuTable:
    otuTable.write("otu\t")
    samples = ["sample" + str(i) for i in range(10)]
    otuTable.write("\t".join(samples) + "\n")
    for i in range(len(otuNames)):
        otuTable.write(list(otuNames.keys())[i].replace(">","") + "\t")
        otuTable.write("\t".join([str(random.randint(0,20)) for j in range(10)]))
        otuTable.write("\n")# to be continued ?

# now to generate the Metadata file


