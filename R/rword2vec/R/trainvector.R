trainvector <- function(trainfile,outfile,dictfile,size=200,window=5,sample=1e-3,hs=0,negative=5,threads=12,iter=5,mincount=5,alpha=0.025,cbow=1)
{
	if (!file.exists(trainfile)) stop("Can't find the train file!")
	traindir <- dirname(trainfile)
	if(missing(outfile)) {
		outfile <- gsub(gsub("^.*\\.", "", basename(trainfile)), "bin", basename(trainfile))
		outfile <- file.path(traindir, outfile)
	}
	if(missing(dictfile)){
		dictfile <- gsub(gsub("^.*\\.", "", basename(trainfile)), "dic", basename(trainfile))
		dictfile <- file.path(traindir, dictfile)
	}
	trainfile <- normalizePath(trainfile, winslash = "/", mustWork = FALSE)
	outfile <- normalizePath(outfile, winslash = "/", mustWork = FALSE)
	dictfile <- normalizePath(dictfile, winslash = "/", mustWork = FALSE)
	
	.Call("TrainVector",trainfile,outfile,dictfile,size,window,sample,hs,negative,threads,iter,mincount,alpha,cbow)
}
