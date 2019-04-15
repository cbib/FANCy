
########### Libraries #################

# needs libxml2-devel installed on system

library(FactoMineR)
library(ggplot2)
suppressWarnings(suppressMessages(library(gplots)))
suppressWarnings(suppressMessages(library(viridis)))
library(RColorBrewer)
library(pheatmap)
suppressWarnings(suppressMessages(library(DESeq2)))

####################### functions ##############
options(bitmapType='cairo')


loadData = function(fileLocation){

  dataset = read.csv(fileLocation)

  rownames(dataset) <- dataset$X
  dataset = subset(dataset, select = -X)

  # remove the file ending from the Sample names ("SAMPLE.sam.match_0.5")
  correctedColsA=sapply(colnames(dataset), function(x){strsplit(x,"[.]")[[1]][1]})
  colnames(dataset) = correctedColsA

  # Remove all pathways with no abundances in any sample.
  dataset = dataset[!apply(dataset, 1, function(x) all(x==0.00)),]


  return(dataset)
}

saveData = function(fileLocation,dataset){
  write.csv(dataset,fileLocation)
}



getMetadataVector = function(metadataFile){

  # read in the metadata, containing the conditions for each run we wanr to filter by
  metadata = read.csv(metadataFile,header = TRUE, sep = ",", stringsAsFactors=FALSE)

  # here's the dataframe variant of the condition table. as we want it.
  # The treeStates char vector is the one we get as input, the colnames being extracted as usual from the results of the pipeline.
  seqDesign = data.frame(row.names = metadata[,1], condition = metadata[,2], stringsAsFactors=FALSE)

  return(seqDesign)

}

pvalCalculator = function(dataset, groupingVector, outputDir,grp1,grp2){
  # This function initializes the dataset,
  # then calculates the p-values for a wilcoxon test between 2 elements of the users choice from the grouping vector
  pvals <- matrix(ncol=4, nrow = nrow(dataset))
  colnames(pvals) = c("Pathway","pval","fdr","logFC")

   if( length(rownames(groupingVector)) != length(colnames(dataset)) ){
       stop("The number of samples in your dataset and grouping vector don't match.")

  }

  
  for(i in 1:nrow(dataset)){
    A = sapply(dataset[i,rownames(groupingVector)[(groupingVector == grp1)]], as.numeric)
    B = sapply(dataset[i,rownames(groupingVector)[(groupingVector == grp2)]], as.numeric)
    if(length(A) == 0 || length(B) == 0 ){
    	stop("One of your grouping variables produces no output, are you sure they match those in the Metadata Vector :", grp1 , " ", grp2, "\n")
    }
    test = wilcox.test(A,B)

    pvals[i,1] = rownames(dataset)[i]
    pvals[i,2] =test$p.value
    pvals[i,4] = log((mean(A)) / (mean(B) ))


  }

  ## Adjusted P values addition
  pvals = pvals[ grep("NaN", pvals[,2], invert=TRUE),]

  pvalList = sapply(pvals[,2], as.numeric)

  pvalAdjustedList = p.adjust(pvalList,method="fdr")

  padjusted = t(pvalAdjustedList)
  for (i in 1:nrow(pvals)){
    pvals[i,3] = padjusted[i]
  }
  write.csv(pvals, paste(outputDir, "/pvals_", grp1,"-",grp2,".csv", sep="", row.names=FALSE))

  return(list("pvals" = pvals, "grp1" = grp1, "grp2" = grp2))
}

significantPathwaysFinder = function(pvalueDF,dataset,maxPval){

  # get pathway names

  significant_pathways_correctedP_rows = pvalueDF[as.double(pvalueDF[,2]) <= maxPval,1]
  
  sign_pathways_corr =dataset[significant_pathways_correctedP_rows,]

  colnames(sign_pathways_corr) = sapply(colnames(sign_pathways_corr),function(x) {strsplit(x,"[.]")[[1]][1]})

  return(sign_pathways_corr)
}

visuHeatmap = function(significantPathways, annotationColDF, pheatmapFile){
  if(nrow(significantPathways) == 0){
    print("There are no significant differentially expressed pathways (FDR corrected pval <= User given p value), no heatmap will be generated.")
  } else{

    # trick for log -> add 1 to all DF values to avoid "Inf" results.
    pheatmap(as.matrix(log(significantPathways + 1)),
             density.info="none",  # turns off density plot inside color legend
             trace="none",         # turns off trace lines inside the heat map
             margins =c(12,13),     # widens margins around plot
             col=rev(inferno(256)),       # use the reversed Viridis Inferno color palette
             dendrogram="both",     # only draw a row dendrogram
             border_color=NA,
             cellwidth=10,
             cellheight=10,
             annotation_col = annotationColDF,
             filename=pheatmapFile
    );
  }

}

pcaPlotter = function(dataset,annotationData,fileName){
  # order of the dataset's samples and annotationdata samples needs to be the same, 
  # or their combination assigns the wrong metadata to the wrong samples.


  dataset = dataset[, order(colnames(dataset)) ]
  annotationData = annotationData[order(rownames(annotationData)), ]
  




  binded = cbind.data.frame(t(dataset),annotationData)
  res.pca = PCA(binded, quali.sup = length(binded), graph= FALSE)

  png(fileName,    # create PNG for the heat map
      width = 5*300,        # 5 x 300 pixels
      height = 5*300,
      res = 300,            # 300 pixels per inch
      pointsize = 8);        # smaller font size

  plot.PCA(res.pca, label="none", choix="ind",title="", habillage=length(binded));

  invisible(dev.off());

}

############Executed code####################




args = commandArgs(trailingOnly=TRUE)

dataset = args[[1]]
metadata = args[[2]]
outputDir = args[[3]]
pval = as.double(args[[4]])
grp1 = args[[5]]
grp2 = args[[6]]

path_abun = loadData(dataset)

seqDesign = getMetadataVector(metadata)

pvalsList = pvalCalculator(path_abun,seqDesign, outputDir,grp1,grp2)
pvals = pvalsList$pvals

sign_pathways = significantPathwaysFinder(pvals,path_abun,pval)

visuHeatmap(sign_pathways, seqDesign, paste(outputDir,"/heatmap.png", sep=""))

pcaPlotter(path_abun,seqDesign, paste(outputDir,"/PCA.png", sep=""))

saveData(dataset,path_abun)
