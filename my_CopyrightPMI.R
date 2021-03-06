# Savage et al. (2018) https://github.com/pesavage/copyright
# PMI (percent melodic identity) analysis
# Usage: Rscript --vanilla ./my_CopyrightPMI.R >& log.$(date +%F).txt

# Clear the decks
rm(list = ls())

#install and load packages
#install.packages("seqinr")
#install.packages("ROCR")
# https://bioconductor.org/packages/release/bioc/html/Biostrings.html
#install.packages("BiocManager")
#BiocManager::install("Biostrings")
library(seqinr)
library(Biostrings)
library(ROCR)

file.ROC <- "https://raw.githubusercontent.com/pesavage/copyright/master/ROC.csv"
file.PMI <- "https://raw.githubusercontent.com/pesavage/copyright/master/PMI.csv"
file.20CopyrighCaseSequences <- "https://raw.githubusercontent.com/pesavage/copyright/master/20CopyrighCaseSequences.csv"
copy<-read.csv(file=file.20CopyrighCaseSequences, header=FALSE)

#set Gap opening and gap extension penalties
gop<-12
gep<-6

#save sequences as strings
out <- matrix(NA, nrow=0, ncol=2)

for (j in 1:length(copy[,1])){
  s3 <- c2s(copy[j,2])
  s4<- c2s(copy[j,3])
  (globalAligns3s4<-pairwiseAlignment(s3, s4, type="global", substitutionMatrix = NULL, gapOpening = gop,gapExtension = gep))
  
  # Print out the optimal global alignment and its score
  pid<-pid(globalAligns3s4,type="PID4")
  #find percent identity
  globalAligns3s4 <- pairwiseAlignment(s3, s4, type="global", substitutionMatrix = NULL, gapOpening = gop,gapExtension = gep, scoreOnly = TRUE)
  
  generateSeqsWithMultinomialModel <- function(inputsequence, X){     
    # Change the input sequence into a vector of letters      
    require("seqinr") # This function requires the SeqinR package.      
    inputsequencevector <- s2c(inputsequence)      # Find the frequencies of the letters in the input sequence "inputsequencevector":      
    mylength <- length(inputsequencevector)      
    mytable <- table(inputsequencevector)      # Find the names of the letters in the sequence      
    letters <- rownames(mytable)      
    numletters <- length(letters)      
    probabilities <- numeric() # Make a vector to store the probabilities of letters      
    for (i in 1:numletters){         
      letter <- letters[i]
      count <- mytable[[i]]
      probabilities[i] <- count/mylength
      }
    # Make X random sequences using the multinomial model with probabilities "probabilities"      
    seqs <- numeric(X)      
    for (j in 1:X){
      seq <- sample(letters, mylength, rep=TRUE, prob=probabilities) # Sample with replacement         
      seq <- c2s(seq)         
      seqs[j] <- seq      
      }      
    # Return the vector of random sequences      
    return(seqs)   
    }
  
  randomseqs <- generateSeqsWithMultinomialModel(s4,100) 
  randomscores <- double(100) # Create a numeric vector with 100 elements
  for (i in 1:100){
    score <- pairwiseAlignment(s3, randomseqs[i], type="global", substitutionMatrix = NULL, gapOpening = gop, gapExtension = gep, scoreOnly = TRUE)
    randomscores[i] <- score
    }
  
  hist(randomscores, col="red") # Draw a red histogram
  
  sum(randomscores >= globalAligns3s4)
# [1] 0 
#i.e., 0/100 random sequences were greater than observed match score
#i.e., p<0.01
  
  pmi<-cbind(pid,(sum(randomscores >= globalAligns3s4)/100))
  out <- rbind(out,pmi)
}

colnames(out)<-c("PMI","P")
write.csv(out,"PMI.csv")

#Adapted from https://www.r-bloggers.com/a-small-introduction-to-the-rocr-package/

roc<-read.csv(file=file.ROC, header=F)
pmi<-read.csv(file=file.PMI, header=T)
pred <- prediction(pmi[,2],roc[,2])

roc.perf = performance(pred, measure = "tpr", x.measure = "fpr")
plot(roc.perf)
abline(a=0, b= 1)

opt.cut = function(perf, pred){
	cut.ind = mapply(FUN=function(x, y, p){
	d = (x - 0)^2 + (y-1)^2
	ind = which(d == min(d))
	c(sensitivity = y[[ind]], specificity = 1-x[[ind]],
	cutoff = p[[ind]])
	}, perf@x.values, perf@y.values, pred@cutoffs)
	}
print(opt.cut(roc.perf, pred))

auc.perf = performance(pred, measure = "auc")

auc.perf@y.values

#system("open .")

# Print R version and packages
sessionInfo()


