unitmatrix<-function(m){
	if(!is.matrix(m)) stop("The input argument is not a matrix");
	t(apply(m,1,function(x){x/sqrt(sum(x^2))}))
}
cosdist<-function(unitm,word,num=20){
	if(!is.matrix(unitm)) stop("The input argument is not a matrix");
	wordvec <-  unitm[rownames(unitm)==word,]
	if(!length(wordvec)) stop(paste("Can't find the the word ",word," in the matrix!"));
	res <- sort(apply(unitm,1,function(x,y){sum(x*y)},wordvec),decreasing=TRUE);
	return(res[1:num])
}
analogy<- function(unitm,word1,word2,word3,num=20){
	if(!is.matrix(unitm)) stop("The input argument is not a matrix");
	vec1 <- unitm[rownames(unitm)==word1,]
	vec2 <- unitm[rownames(unitm)==word2,]
	vec3 <- unitm[rownames(unitm)==word3,]
	if(!length(vec1)) stop(paste("Can't find the the word ",word1," in the matrix!"));
	if(!length(vec2)) stop(paste("Can't find the the word ",word2," in the matrix!"));
	if(!length(vec3)) stop(paste("Can't find the the word ",word3," in the matrix!"));
	vec <- vec3+(vec2-vec1);
	vec <- vec/sqrt(sum(vec^2));
	res <- sort(apply(unitm,1,function(x,y){sum(x*y)},vec),decreasing=TRUE);
	return(res[1:num])
}
