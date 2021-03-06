% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\docType{data}
\name{sail-internal}
\alias{sail-internal}
\alias{SoftThreshold}
\alias{l2norm}
\alias{cbbPalette}
\alias{nonzero}
\alias{check_col_0}
\title{Internal sail functions}
\format{An object of class \code{character} of length 8.}
\usage{
SoftThreshold(x, lambda)

l2norm(x)

cbbPalette

nonzero(beta, bystep = FALSE)

check_col_0(M)
}
\arguments{
\item{x}{numeric value of a coefficient}

\item{lambda}{tuning parameter value}

\item{beta}{vector or 1 column matrix of regression coefficients}

\item{bystep}{\code{bystep = FALSE} means which variables were ever nonzero.
\code{bystep = TRUE} means which variables are nonzero for each step}

\item{M}{is a matrix}
}
\description{
Internal sail helper functions

\code{cbbPalette} gives a Color Blind Palette

\code{nonzero} is to determine which coefficients are non-zero

\code{check_col_0} is to check how many columns are 0 and is
  used in the fitting functions \code{lspath}
}
\details{
These functions are not intended for use by users.
}
\keyword{datasets}
