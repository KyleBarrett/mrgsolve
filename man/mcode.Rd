% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mcode.R
\name{mcode}
\alias{mcode}
\alias{mcode_cache}
\title{Write, compile, and load model code}
\usage{
mcode(model, code, project = tempdir(), ...)

mcode_cache(model, code, project = tempdir(), ...)
}
\arguments{
\item{model}{model name}

\item{code}{character string specifying a \code{mrgsolve} model}

\item{project}{project name}

\item{...}{passed to \code{\link{mread}}}
}
\description{
This is a convenience function that ultimately calls \code{\link{mread}}.
}
\details{
Note that the arguments are in slightly different order than 
\code{\link{mread}}.  The default \code{project} is \code{tempdir()}.
}
\examples{

\dontrun{ 
code <- '
$CMT DEPOT CENT
$PKMODEL ncmt=1, depot=TRUE
$MAIN
double CL = 1;
double V = 20;
double KA = 1;
'

mod <- mcode("example",code)
}

}
\seealso{
\code{\link{mread}}, \code{\link{mread_cache}}
}
