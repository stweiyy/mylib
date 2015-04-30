\name{rword2vec-package}
\alias{rword2vec-package}
\alias{rword2vec}
\docType{package}
\title{
	R interface for word2vec
}
\description{
This R package for interface of Google's word2vec.
}
\details{
\tabular{ll}{
Package: \tab rword2vec\cr
Type: \tab Package\cr
Version: \tab 1.0\cr
Date: \tab 2015-04-30\cr
License: \tab Apache License\cr
}
This package provide an interface for the Google word2vec project.
mainly two C extension programs, one is training the text file then generate the vectors,the 
other is to load the vectors. Based on these two function, you can do the calculation
use the word vectors, Such as calculate the cosine distance of two words.
}
\author{
Whisly Wei

Maintainer: Whisly <stweiyy@163.com>
}
\references{
Google word2vec
}
\keyword{ package }
\seealso{
~~ \code{\link[<pkg>:<pkg>-package]{<pkg>}} ~~
}
