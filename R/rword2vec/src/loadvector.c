#include <R.h>
#include <Rinternals.h>
#include <Rdefines.h>

/*Load the word2vec vector from the model file */

SEXP LoadVector(SEXP model){

	PROTECT(model = AS_CHARACTER(model));
	char *filename=R_alloc(strlen(CHAR(STRING_ELT(model,0))),sizeof(char));
	strcpy(filename,CHAR(STRING_ELT(model,0)));
	Rprintf("Loading vectors from : %s  ...\n",filename);

	FILE *fp=fopen(filename,"rb");
	if(!fp){
		Rprintf("Open %s failed ...\n",filename);
		UNPROTECT(1);
		return (R_NilValue);
	}
	long long wordscount,wordsdim;
	fscanf(fp,"%lld",&wordscount);
	fscanf(fp,"%lld",&wordsdim);
	Rprintf("words dict contains %lld words,dimension: %lld\n",wordscount,wordsdim);

	/*construct the matrix of the vector */
	SEXP m,wordslist;
	PROTECT(m = allocMatrix(REALSXP, wordscount, wordsdim));
	PROTECT(wordslist = allocVector(STRSXP,wordscount));

	double *rm = REAL(m);
	int i,j,k;
	char buf[512];
	
	for(i=0;i<wordscount;i++){
		bzero(buf,512);
		k=0;
		while(1){
			buf[k]=fgetc(fp);
			if(feof(fp) || buf[k] ==' ') break;
			if(buf[k]!='\n') k++;
		}
		buf[k]=0;

		SET_STRING_ELT(wordslist,i,mkChar(buf));

		float cor;
		for(j=0;j<wordsdim;j++){
			fread(&cor,sizeof(float),1,fp);
			rm[wordscount * j + i] =(double)cor;
		}
	}
	SEXP dimnames;
	PROTECT(dimnames = allocVector(VECSXP,2));
	SET_VECTOR_ELT(dimnames,0,wordslist);

	setAttrib(m,R_DimNamesSymbol,dimnames);
	fclose(fp);
	UNPROTECT(4);
	return m;
}
