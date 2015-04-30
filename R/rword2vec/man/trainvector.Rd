\name{trainvector}
\alias{trainvector}
\title{Train the vectors from the input file}
\usage{
trainvector(trainfile,outfile,dictfile,size=200,window=5,sample=1e-3,hs=0,negative=5,threads=12,iter=5,mincount=5,alpha=0.025,cbow=1)
}
\arguments{
\item{trainfile}{Path of the train file.}

\item{outfile}{Path of the output file.}

\item{dictfile}{Path of the generated dictionary file.}

\item{size}{Set size of word vectors; default is 200.}

\item{window}{Set max skip length between words; default is 5.}

\item{sample}{Set threshold for occurrence of words. Those that appear with higher frequency in the training data will be randomly down-sampled; default is 1e-3, useful range is (0, 1e-5)}

\item{hs}{Use Hierarchical Softmax; default is 0 (not used).}

\item{negative}{Number of negative examples; default is 5, common values are 3 - 10 (0 = not used).}

\item{threads}{The number of threads (default 12).}

\item{iter}{Run more training iterations (default 5).}

\item{mincount}{This will discard words that appear less than \code{mincount} times; default is 5.}

\item{alpha}{Set the starting learning rate; default is 0.025 for skip-gram and 0.05 for CBOW.}

\item{cbow}{Use the continuous bag of words model; default is 1 (use 0 for skip-gram model).}

}
\value{
	No return value
}
\description{
Train a model by word2vec.
}
\details{
The word2vec tool takes a text corpus as input and produces the
word vectors as output. It first constructs a vocabulary from the
training text data and then learns vector representation of words.
The resulting word vector file can be used as features in many
natural language processing and machine learning applications.
}
\author{
Whisly Wei <\email{stweiyy@163.com}>
}
\references{
\url{https://code.google.com/p/word2vec/}
}

