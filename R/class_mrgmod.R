# Copyright (C) 2013 - 2018  Metrum Research Group, LLC
#
# This file is part of mrgsolve.
#
# mrgsolve is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# mrgsolve is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with mrgsolve.  If not, see <http://www.gnu.org/licenses/>.

valid_funs <- function(x) {
  x1 <- length(x)==4
  x2 <- identical(names(x), c("main", "ode", "table", "config"))
  if(x1 & x2) return(list(TRUE,""))
  return(list(FALSE, 
              c("Invalid functions specification.",
                "This model object is not compatible with the current mrgsolve version.",
                "Rebuild the model object or upgrade the mrgsolve version.")))
}

check_names <- function(x,par,cmt) {
  
  x <- x[!is.element(x,c(".", "..."))]
  
  dups <- any(duplicated(x))
  us <-  any(charthere(x,"_"))
  res <- any(is.element(x,Reserved))
  
  ans <- character(0)
  
  ## Duplicate names are not allowed
  if(dups) {
    tmp <- paste(x[duplicated(x)], collapse=" ")
    ans <- c(ans,paste0("Duplicated model names: ", tmp))
  }
  ## Look for names in the Reserved word list
  if(res) {
    tmp <- paste(x[is.element(x,Reserved)],collapse=" ")
    ans <- c(ans,paste0("Reserved words in model names: ",tmp))
  }
  ## Scan for names with underscores
  ## Leading underscores are not allowed
  ## Also, look for any name that conflicts with
  ##   bioav, lag-time, or infusion duration or ate
  if(us) {
    ans <- check_us(x,cmt,ans)
  }
  return(ans)
}

check_us <- function(x,cmt,ans) {
  leading <- x[substr(x,1,1)=="_"]
  if(length(leading) > 0) {
    ans <- c(ans, 
             paste0("Leading underscore not allowed: ", 
                    paste(leading, collapse=" "))) 
  }
  check <- as.character(sapply(c("F_", "ALAG_", "D_", "R_"),paste0,cmt))
  iv_name <- intersect(x,check)
  if(length(iv_name) > 0) {
    ans <- c(ans, 
             paste0("Reserved symbols in model names: ", iv_name))
  } 
  return(ans)
}

check_globals <- function(x,cmt) {
  ans <- character(0)
  us <-  any(charthere(x,"_"))
  res <- any(is.element(x,Reserved_cvar))
  if(res) {
    tmp <- paste(x[is.element(x,Reserved_cvar)],collapse=" ")
    ans <- c(ans,paste0("Reserved words in model names: ",tmp))
  }
  if(us) {
    ans <- check_us(x,cmt,ans) 
  }
  return(ans)
}

protomod <- list(model=character(0),
                 modfile = character(0),
                 package=character(0),
                 soloc=tempdir(),
                 project='.',
                 start = 0.0,
                 end=24.0,
                 delta=1.0,
                 add = numeric(0),
                 tscale = as.double(1),
                 digits=-1,
                 quiet = FALSE,
                 verbose = FALSE,
                 debug=FALSE,
                 preclean=FALSE,
                 atol=1E-8,
                 rtol=1E-8,
                 maxsteps=2000,
                 hmin=0,
                 hmax=0,
                 ixpr=0,
                 mxhnil=0,
                 shlib=list(date="",par="", cmt="", compiled=FALSE, 
                            version=NULL, source=""),
                 funs = c(main=character(0),
                          ode=character(0),
                          table=character(0),
                          config=character(0)),
                 omega=new("omegalist"),
                 sigma = new("sigmalist"),
                 request="(all)",
                 param = new("parameter_list"),
                 init=new("cmt_list"),
                 capture=character(0),
                 args = list(),
                 fixed  = list(),
                 advan=13,
                 trans=1,
                 mindt=10*.Machine$double.eps,
                 code = character(0),
                 annot = list(),
                 envir = new.env(),
                 plugin = character(0)
)

slot.names <- names(protomod)
slots <- sapply(protomod, class)
names(slots) <- names(protomod)

valid.mrgmod <- function(object) {
  tags <- unlist(names(object), use.names=FALSE)
  x <- check_names(tags,Pars(object),Cmt(object))
  x1 <- length(x)==0
  x2 <- object@advan %in% c(1,2,3,4,13)
  fun <- valid_funs(object@funs)
  cool <- x1 & x2 & fun[[1]]
  if(cool) return(TRUE)
  x <- c(x,fun[[2]])
  if(!x2) x <- c(x,"Advan must be 1, 2, 3, 4, or 13")
  return(x)
}

##' S4 class for mrgsolve model object
##'
##' @section Notes:
##' \itemize{
##' \item Spaces in paths (\code{project} and \code{soloc}) are prohibited.
##'
##' }
##'
##' @slot model model name \code{<character>}
##' @slot modfile source model specification file name \code{<character>}
##' @slot package the shared object file name \code{character>}
##' @slot project working directory; must be writeable with no spaces \code{<character>}
##' @slot start simulation start time \code{<numeric>}
##' @slot end simulation end time \code{<numeric>}
##' @slot delta simulation time interval \code{<numeric>}
##' @slot add additional simulation times \code{<numeric-vector>}
##' @slot param \code{<parameter_list>}
##' @slot fixed a \code{<parameter_list>} of fixed value parameters; 
##' these are not updatable from \code{R}
##' @slot init \code{<cmt_list>}
##' @slot events deprecated
##' @slot digits significant digits in simulated output; negative integer means ignore \code{<numeric>}
##' @slot hmin passed to \code{\link[=solversettings]{dlsoda}}  \code{<numeric>}
##' @slot hmax passed to \code{\link[=solversettings]{dlsoda}} \code{<numeric>}
##' @slot mxhnil passed to \code{\link[=solversettings]{dlsoda}} \code{<numeric>}
##' @slot ixpr passed to \code{\link[=solversettings]{dlsoda}} \code{<numeric>}
##' @slot atol passed to \code{\link[=solversettings]{dlsoda}} \code{<numeric>}
##' @slot rtol passed to \code{\link[=solversettings]{dlsoda}} \code{<numeric>}
##' @slot maxsteps passed to \code{\link[=solversettings]{dlsoda}} \code{<numeric>}
##' @slot preclean passed to R CMD SHLIB during compilation \code{<logical>}
##' @slot verbose print run information to screen \code{<logical>}
##' @slot quiet print various information to screen \code{<logical>}
##' @slot debug not used
##' @slot tscale used to scale time in simulated output \code{<numeric>}
##' @slot omega \code{\link{matlist}} for simulating individual-level random effects
##' @slot sigma \code{\link{matlist}} for simulating residual error variates
##' @slot args \code{<list>} of arguments to be passed to \code{\link{mrgsim}}
##' @slot advan either 2, 4, or 13 \code{<numeric>}
##' @slot trans either 1, 2, 4, or 11 \code{<numeric>}
##' @slot request  vector of compartments to request \code{<character>}
##' @slot soloc directory path for storing the model shared object \code{<character>}
##' @slot code a character vector of the model code
##' @slot capture a character vector of variables that are captured from 
##' the simulation \code{<character>}
##' @slot mindt minimum time between simulation records \code{<numeric>}
##' @slot envir internal model environment \code{<environment>}
##' @slot shlib a list of data related to build outcome \code{<list>}
##' @slot annot model annotations \code{<list>}
##' @slot plugin model plugins \code{<character>}
##' 
##' @seealso \code{\link{update}}, \code{\link{solversettings}}
setClass("mrgmod",slots=slots, validity=valid.mrgmod, prototype=protomod)

setClass("packmod",
         prototype = list(shlib=list(compiled=TRUE, date="date of package compile"),
                          package="", src="", header=""),
         contains="mrgmod",
         slots=c(
           package="character",
           src="character", 
           header="character"
         )
)

##' Return a pre-compiled, PK/PD model
##' 
##' @param ... passed to update
##' 
##' @return 
##' A \code{packmod} object, ready to simulate.
##' 
##' @examples
##' 
##' mod <- mrgsolve:::house()
##' 
##' see(mod)
##' 
##' mod %>% ev(amt=100) %>% mrgsim %>% plot
##' 
house <- function(...) {
  att <- readRDS(file=pfile("mrgsolve", "project", "housemodel", "RDS"))
  x <- new("packmod",
           att,
           package = "mrgsolve",
           model = "housemodel"
  )
  x@soloc <- dirname(sodll(x))
  x <- compiled(x,TRUE)
  x <- update(x,...,open=TRUE)
  x
}

as_pack_mod <- function(model, project, PACKAGE) {
  x <- mread(model, project, compile=FALSE, udll=FALSE, ns=FALSE)
  code <- readLines(cfile(x),warn=FALSE)
  x <- new("packmod",
           x,
           package=PACKAGE,
           model = model
  )
  soloc <- soloc(x)
  source <- file.path(soloc,compfile(model(x)))
  x@shlib$par <- Pars(x)
  x@shlib$cmt <- Cmt(x)
  x@shlib$source <- NULL
  x@code <- code
  x <- relocate_funs(x, PACKAGE)
  x@soloc <- ""
  
  return(list(mod=x, soloc=soloc, source=source))
}

##' Check if an object is a model object 
##' 
##' The function checks to see if the object is either
##'  \code{mrgmod} or \code{packmod}.
##' 
##' @param x any object
##' @return \code{TRUE} if \code{x} inherits \code{mrgsims}.
##' @export
is.mrgmod <- function(x) inherits(x,c("mrgmod","packmod"))

see_compfile <- function(x) {
  file <- file.path(soloc(x),compfile(model(x)))
  if(!file_exists(file)) {
    message("could not find the compiled code for this model.")
  }
  cat(readLines(file),sep="\n")
}

setMethod("project", "mrgmod", function(x,...) {
  return(x@project)
})

setMethod("project", "packmod", function(x,...) {
  return(file.path(path.package(x@package),"project"))
})

##' @rdname cmtn
##' @param tag compartment name
##' @export
setMethod("cmtn", "mrgmod", function(x,tag,...) {
  return(which(cmt(x)==tag))
})

neq <- function(x) length(Init(x))
npar <- function(x) length(Pars(x))
pars <- function(x) names(param(x))
shlib <- function(x) x@shlib
cmt <- function(x) names(Init(x))
dllname <- function(x) x@package
model <- function(x) x@model
modfile <- function(x) x@modfile
Param <- function(x) x@param
Param_list <- function(x) x@param@data
Pars <-  function(x) names(x@param@data)
Init <- function(x) x@init
Cmt <-  function(x) names(x@init@data)


##' Return the location of the model shared object
##'
##' @param x model object
##' @param short logical; if \code{TRUE}, \code{soloc} will
##'  be rendered  with a short path name
##' 
##' @rdname soloc
##' 
##' @examples
##' mod <- mrgsolve:::house()
##' soloc(mod)
##' 
##' @export
soloc <- function(x,short=FALSE) {
  if(short) return(build_path(x@soloc))
  return(x@soloc)
}

cfile <- function(x,...) {
  return(pathfun(filename(project(x),modfile(x),...)))
}

setMethod("sodll", "mrgmod", function(x,...) {
  return(pathfun(file.path(soloc(x,...),dllfile(x))))
})

setMethod("sodll", "packmod", function(x,...) {
  return(pathfun(getLoadedDLLs()[[x@package]][["path"]]))
})

##' Get all names from a model object
##' 
##' @param x the model object
##' 
##' @aliases names,mrgmod-method
##' 
##' @examples
##' mod <- mrgsolve:::house()
##' names(mod)
##' 
##' @export
setMethod("names", "mrgmod", function(x) {
  ans <- list()
  ans$param <- Pars(x)
  ans$init <- Cmt(x)
  ans$omega <- list(names(omat(x)),unlist(labels(omat(x)),use.names=FALSE))
  ans$sigma <- list(names(smat(x)),unlist(labels(smat(x)),use.names=FALSE))
  return(ans)
})

##' Coerce a model object to list.
##' 
##' @param x mrgmod object
##' @param deep if \code{TRUE}, extra information is returned
##' (see details). 
##' @param ... not used
##' 
##' @details 
##' If \code{deep} is \code{TRUE}, then the values for
##' \code{trans}, \code{advan}, and \code{mindt} are
##' returned as well as a summary of internal model 
##' functions (with a call to \code{mrgsolve:::funset}).
##' 
##' @rdname as.list_mrgmod
##' @export
setMethod("as.list", "mrgmod", function(x, deep = FALSE, ...) {
  
  within(list(), {
    verbose <- x@verbose
    debug <- x@debug
    preclean <- x@preclean
    mindt <- x@mindt
    tscale <- x@tscale
    request <- x@request
    digits <- x@digits
    plugins <- x@plugin
    envir <- x@envir
    hmax <- x@hmax
    hmin <- x@hmin
    maxsteps <- x@maxsteps
    rtol <- x@rtol
    atol <- x@atol
    if(deep) {
      trans <- x@trans
      advan <- x@advan
      functions <- funset(x)
    }
    details <- x@annot
    code <- x@code
    random <- names(x)[c("omega", "sigma")]
    request <- x@request
    capture <- x@capture
    add <- x@add
    delta <- x@delta
    end <- x@end
    start <- x@start
    shlib <- shlib(x)
    cfile <- cfile(x)
    sodll <- sodll(x)
    soloc <- soloc(x)
    project <- project(x)
    model <- model(x)
    fixed <- as.list(x@fixed)
    sigma <- as.list(smat(x))
    omega <- as.list(omat(x))
    init <- as.list(init(x))
    param <- as.list(param(x))
    cmt <- cmt(x)
    covariates <- as.character(x@shlib$covariates)
    pars <- pars(x)
    neq <- neq(x)
    npar <- npar(x)
  })
})


##' DEPRECATED: get an events object from a model object
##' 
##' @param x an object
##' @param ... not used
##' 
##' @export
setGeneric("events", function(x,...) {
  standardGeneric("events")
})

##' @rdname events
##' @export
setMethod("events", "mrgmod", function(x,...) {
  warning("events are no longer included in the model object")
})



##' @rdname see
##' @export
setMethod("see", "mrgmod", function(x,raw=FALSE, ...) {
  if(raw) return(x@code)
  what <- x@code
  if(length(what)==0) {
    if(file_exists(cfile(x))) what <- readLines(cfile(x), warn=FALSE)
  }
  if(length(what)==0) {
    warning("No code to show.")
  } else {
    cat("\nModel file: ", basename(cfile(x)), "\n")
    cat(what, sep="\n")
  }
  return(invisible(NULL))
})

##' @rdname loadso
##' @export
setMethod("loadso", "mrgmod", function(x,...) {
  if(.Platform$OS.type!="unix") try(dyn.unload(sodll(x)),silent=TRUE)
  foo <- try(dyn.load(sodll(x)))
  if(class(foo)=="try-catch") {
    message(foo)
    return(invisible(FALSE))
  }
  return(invisible(x))
})

setMethod("unloadso", "mrgmod", function(x, ...) {
  out <- try(dyn.unload(sodll(x)), TRUE)
  if(inherits(out, "try-error")) {
    stop(out[1])
  } else {
    message("unloaded ", sodll(x))
  }
  return(invisible(NULL))
})


##' @rdname tgrid
##' @export
setMethod("stime", "mrgmod",  function(x,...) {
  render_time(x)
})

##' @rdname revar
##' @export
setMethod("revar", "mrgmod", function(x,...) {
  return(list(omega=x@omega,sigma=x@sigma))
})

##' @rdname blocks
##' @export
setMethod("blocks", "mrgmod", function(x,...) {
  what <- as.character(match.call()[-1])[-1]
  blocks_(cfile(x),what)
})

##' @rdname blocks
##' @export
setMethod("blocks", "character", function(x,...) {
  what <- as.character(match.call()[-1])[-1]
  blocks_(x,what)
})

blocks_ <- function(file,what) {
  if(length(what)==0) what <- c("PARAM","MAIN", "ODE","DES", "TABLE")
  if(!file_exists(file)) stop("Can't find model file", call.=FALSE)
  bl <- modelparse(readLines(file, warn=FALSE))
  if(!any(what == "all")) bl <- bl[names(bl) %in% what]
  if(length(bl)==0) {
    message("No blocks found.")
    return(invisible(NULL))
  }
  
  bl <- lapply(bl, paste, collapse="\n")
  x1 <- paste0("$", names(bl), "\n")
  cat("\nModel file:",basename(file), "\n\n")
  cat(paste0(x1,unlist(bl)), sep="\n\n")
}

parin <- function(x) {
  list(rtol=x@rtol,atol=x@atol, hmin=as.double(x@hmin), 
       hmax=as.double(x@hmax), ixpr=x@ixpr, 
       maxsteps=as.integer(x@maxsteps),mxhnil=x@mxhnil,
       verbose=as.integer(x@verbose),debug=x@debug,
       digits=x@digits, tscale=x@tscale,
       mindt=x@mindt, advan=x@advan)
}

##' Show model specification and C++ files.
##' 
##' @param x model object
##' @param spec logical; show the model specification file
##' @param source logical; show the C++ file that is actually compiled
##' @param ... not used
##' @export
##' 
file_show <- function(x,spec=TRUE,source=TRUE,...) {
  stopifnot(is.mrgmod(x))
  what <- list()
  if(spec) what$spec <- cfile(x)
  if(source) what$source <- x@shlib$source
  do.call(base::file.show,what)
}


re_build <- function(x,model=model(x),temp = FALSE) {
  if(temp) {
    model <- basename(tempfile(pattern="mod", tmpdir='.'))
  }
  mcode(model,x@code)
}

##' @export
all.equal.mrgmod <- function(target, current) {
  target.env <- as.list(target@envir)
  current.env <- as.list(current@envir)
  target@envir <- current@envir <- new.env()
  t1 <- isTRUE(identical(target,current))
  t2 <- identical(target.env, current.env)
  all(t1,t2)
}