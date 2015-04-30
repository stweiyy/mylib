loadvector <- function(modelfile){
	if (!file.exists(modelfile)) stop("Can't find the model file!")
	.Call("LoadVector",modelfile)
}
