mylibrary <-
function(package, help, pos = 2, lib.loc = NULL, character.only = FALSE,
         logical.return = FALSE, warn.conflicts = TRUE,
	 quietly = FALSE, keep.source = getOption("keep.source.pkgs"),
         verbose = getOption("verbose"))
{
    paste0 <- function(...) paste(..., sep="")
    testRversion <- function(pkgInfo, pkgname, pkgpath)
    {
        if(is.null(built <- pkgInfo$Built))
            stop(gettextf("package '%s' has not been installed properly\n", pkgname),
                 call. = FALSE, domain = NA)

        ## which version was this package built under?
        ## must be >= 2.10.0 (new help system)
        R_version_built_under <- as.numeric_version(built$R)
        if(R_version_built_under < "2.10.0")
            stop(gettextf("package '%s' was built before R 2.10.0: please re-install it",
                          pkgname), call. = FALSE, domain = NA)

        current <- getRversion()
        ## depends on R version?
        ## as it was installed >= 2.7.0 it will have Rdepends2
        if(length(Rdeps <- pkgInfo$Rdepends2)) {
            for(dep in Rdeps)
                if(length(dep) > 1L) {
                    target <- as.numeric_version(dep$version)
                    res <- eval(parse(text=paste("current", dep$op, "target")))
                    if(!res)
                        stop(gettextf("This is R %s, package '%s' needs %s %s",
                                      current, pkgname, dep$op, target),
                             call. = FALSE, domain = NA)
                }
        }
        ## warn if installed under a later version of R
        if(R_version_built_under > current)
            warning(gettextf("package '%s' was built under R version %s",
                             pkgname, as.character(built$R)),
                    call. = FALSE, domain = NA)
        platform <- built$Platform
        r_arch <- .Platform$r_arch
        if(.Platform$OS.type == "unix") {
            ## allow mismatches if r_arch is in use, e.g.
            ## i386-gnu-linux vs x86-gnu-linux depending on
            ## build system.
            if(!nzchar(r_arch) && length(grep("\\w", platform)) &&
               !testPlatformEquivalence(platform, R.version$platform))
                stop(gettextf("package '%s' was built for %s",
                              pkgname, platform),
                     call. = FALSE, domain = NA)
        } else {  # Windows
            ## a check for 'mingw' suffices, since i386 and x86_64
            ## have DLLs in different places.  This allows binary packages
            ## to be merged.
            if(nzchar(platform) && !grepl("mingw", platform))
                stop(gettextf("package '%s' was built for %s",
                              pkgname, platform),
                     call. = FALSE, domain = NA)
        }
        ## if using r_arch subdirs, check for presence
        if(nzchar(r_arch)
           && file.exists(file.path(pkgpath, "libs"))
           && !file.exists(file.path(pkgpath, "libs", r_arch)))
            stop(gettextf("package '%s' is not installed for 'arch=%s'",
                          pkgname, r_arch),
                 call. = FALSE, domain = NA)
    }

    checkLicense <- function(pkg, pkgInfo, pkgPath)
    {
        L <- tools:::analyze_license(pkgInfo$DESCRIPTION["License"])
        if(!L$is_empty && !L$is_verified) {
            site_file <- path.expand(file.path(R.home("etc"), "licensed.site"))
            if(file.exists(site_file) &&
               pkg %in% readLines(site_file)) return()
            personal_file <- path.expand("~/.R/licensed")
            if(file.exists(personal_file)) {
                agreed <- readLines(personal_file)
                if(pkg %in% agreed) return()
            } else agreed <- character()
            if(!interactive())
                stop(gettextf("package '%s' has a license that you need to accept in an interactive session", pkg), domain = NA)
            lfiles <- file.path(pkgpath, c("LICENSE", "LICENCE"))
            lfiles <- lfiles[file.exists(lfiles)]
            if(length(lfiles)) {
                message(gettextf("Package '%s' has a license that you need to accept after viewing", pkg), domain = NA)
                readline("press RETURN to view license")
                encoding <- pkgInfo$DESCRIPTION["Encoding"]
                if(is.na(encoding)) encoding <- ""
                ## difR and EVER have a Windows' 'smart quote' LICEN[CS]E file
                if(encoding == "latin1") encoding <- "cp1252"
                file.show(lfiles[1L], encoding = encoding)
            } else {
                message(gettextf("Package '%s' has a license that you need to accept:\naccording to the DESCRIPTION file it is", pkg), domain = NA)
                message(pkgInfo$DESCRIPTION["License"])
            }
            choice <- menu(c("accept", "decline"),
                           title = paste("License for", sQuote(pkg)))
            if(choice != 1)
                stop(gettextf("License for package '%s' not accepted", package),
                     domain = NA, call. = FALSE)
            dir.create(dirname(personal_file), showWarnings=FALSE)
            writeLines(c(agreed, pkg), personal_file)
        }
    }

    checkNoGenerics <- function(env, pkg)
    {
        nenv <- env
        ns <- .Internal(getRegisteredNamespace(as.name(pkg)))
        if(!is.null(ns)) nenv <- asNamespace(ns)
        if (exists(".noGenerics", envir = nenv, inherits = FALSE))
            TRUE
        else {
            ## A package will have created a generic
            ## only if it has created a formal method.
            length(objects(env, pattern="^\\.__[MT]", all.names=TRUE)) == 0L
        }
    }

    checkConflicts <- function(package, pkgname, pkgpath, nogenerics, env)
    {
        dont.mind <- c("last.dump", "last.warning", ".Last.value",
                       ".Random.seed", ".First.lib", ".Last.lib",
                       ".packageName", ".noGenerics", ".required",
                       ".no_S3_generics", ".Depends")
        sp <- search()
        lib.pos <- match(pkgname, sp)
        ## ignore generics not defined for the package
        ob <- objects(lib.pos, all.names = TRUE)
        if(!nogenerics) {
            ##  Exclude generics that are consistent with implicit generic
            ## from another pacakge.  A better test would be to move this
            ## down into the loop and test against specific other package name
            ## but subtle conflicts like that are likely to be found elsewhere
            these <- objects(lib.pos, all.names = TRUE)
            these <- these[substr(these, 1L, 6L) == ".__T__"]
            gen <- gsub(".__T__(.*):([^:]+)", "\\1", these)
            from <- gsub(".__T__(.*):([^:]+)", "\\2", these)
            gen <- gen[from != package]
            ob <- ob[!(ob %in% gen)]
        }
        fst <- TRUE
	ipos <- seq_along(sp)[-c(lib.pos,
				 match(c("Autoloads", "CheckExEnv"), sp, 0L))]
        for (i in ipos) {
            obj.same <- match(objects(i, all.names = TRUE), ob, nomatch = 0L)
            if (any(obj.same > 0)) {
                same <- ob[obj.same]
                same <- same[!(same %in% dont.mind)]
                Classobjs <- grep("^\\.__", same)
                if(length(Classobjs)) same <- same[-Classobjs]
                ## report only objects which are both functions or
                ## both non-functions.
		same.isFn <- function(where)
		    sapply(same, exists,
                           where = where, mode = "function", inherits = FALSE)
		same <- same[same.isFn(i) == same.isFn(lib.pos)]
                ## if a package imports, and re-exports, there's no problem
		if(length(same))
		    same <- same[sapply(same, function(.)
					!identical(get(., i),
						   get(., lib.pos)))]
                if(length(same)) {
                    if (fst) {
                        fst <- FALSE
                        packageStartupMessage(gettextf("\nAttaching package: '%s'\n",
                                                       package),
                                              domain = NA)
                    }

                    objs <- strwrap(paste(same, collapse=", "), indent=4,
                                    exdent=4)
                    msg <- sprintf("The following object(s) are masked %s '%s':\n\n%s\n",
                                   if (i < lib.pos) "_by_" else "from",
                                   sp[i], paste(objs, collapse="\n"))
		    packageStartupMessage(msg)
                }
            }
        }
    }

    runUserHook <- function(pkgname, pkgpath) {
        hook <- getHook(packageEvent(pkgname, "attach")) # might be list()
        for(fun in hook) try(fun(pkgname, pkgpath))
    }

    bindTranslations <- function(pkgname, pkgpath)
    {
        popath <- file.path(pkgpath, "po")
        if(!file.exists(popath)) return()
        bindtextdomain(pkgname, popath)
        bindtextdomain(paste("R", pkgname, sep="-"), popath)
    }

    if(verbose && quietly)
	message("'verbose' and 'quietly' are both true; being verbose then ..")
    if(!missing(package)) {
        if (is.null(lib.loc)) lib.loc <- .libPaths()
        ## remove any non-existent directories
        lib.loc <- lib.loc[file.info(lib.loc)$isdir %in% TRUE]

	if(!character.only)
	    package <- as.character(substitute(package))
        if(length(package) != 1L)
            stop("'package' must be of length 1")
        if(is.na(package) || (package == ""))
            stop("invalid package name")

	pkgname <- paste("package", package, sep = ":")
	newpackage <- is.na(match(pkgname, search()))
	if(newpackage) {
            ## Check for the methods package before attaching this
            ## package.
            ## Only if it is _already_ here do we do cacheMetaData.
            ## The methods package caches all other libs when it is
            ## attached.

            pkgpath <- .find.package(package, lib.loc, quiet = TRUE,
                                     verbose = verbose)
            if(length(pkgpath) == 0L) {
                txt <- if(length(lib.loc))
                    gettextf("there is no package called '%s'", package)
                else
                    gettext("no library trees found in 'lib.loc'")
                if(logical.return) {
                    warning(txt, domain = NA)
		    return(FALSE)
		} else stop(txt, domain = NA)
            }
            abs_path <- function(x) {cwd <- setwd(x);on.exit(setwd(cwd));getwd()}
            which.lib.loc <- abs_path(dirname(pkgpath))
            pfile <- system.file("Meta", "package.rds", package = package,
                                 lib.loc = which.lib.loc)
            if(!nzchar(pfile))
            	stop(gettextf("'%s' is not a valid installed package",
                              package), domain = NA)
            pkgInfo <- .readRDS(pfile)
            testRversion(pkgInfo, package, pkgpath)
            ## avoid any bootstrapping issues by these exemptions
            if(!package %in% c("datasets", "grDevices", "graphics", "methods",
                               "splines", "stats", "stats4", "tcltk", "tools",
                               "utils") &&
               isTRUE(getOption("checkPackageLicense", FALSE)))
                checkLicense(package, pkgInfo, pkgpath)

            ## The check for inconsistent naming is now in .find.package

            if(is.character(pos)) {
                npos <- match(pos, search())
                if(is.na(npos)) {
                    warning(gettextf("'%s' not found on search path, using pos = 2", pos), domain = NA)
                    pos <- 2
                } else pos <- npos
            }
            .getRequiredPackages2(pkgInfo, quietly = quietly)
            deps <- unique(names(pkgInfo$Depends))
            ## If the name space mechanism is available and the package
            ## has a name space, then the name space loading mechanism
            ## takes over.
            if (packageHasNamespace(package, which.lib.loc)) {
                tt <- try({
                    ns <- loadNamespace(package, c(which.lib.loc, lib.loc),
                                        keep.source = keep.source)
                    dataPath <- file.path(which.lib.loc, package, "data")
                    env <- attachNamespace(ns, pos = pos,
                                           dataPath = dataPath, deps)
                })
                if (inherits(tt, "try-error"))
                    if (logical.return)
                        return(FALSE)
                    else stop(gettextf("package/namespace load failed for '%s'",
                                       package),
                              call. = FALSE, domain = NA)
                else {
                    on.exit(detach(pos=pos))
                    ## If there are S4 generics then the package should
                    ## depend on methods
                    nogenerics <-
                        !.isMethodsDispatchOn() || checkNoGenerics(env, package)
                    if(warn.conflicts &&
                       !exists(".conflicts.OK", envir = env, inherits = FALSE))
                        checkConflicts(package, pkgname, pkgpath,
                                       nogenerics, ns)
                    runUserHook(package, pkgpath)
                    on.exit()
                    if (logical.return)
                        return(TRUE)
                    else
                        return(invisible(.packages()))
                }
            }

            ## non-namespace branch
            codeFile <- file.path(which.lib.loc, package, "R", package)
            ## create environment (not attached yet)
            loadenv <- new.env(hash = TRUE, parent = .GlobalEnv)
            ## save the package name in the environment
            assign(".packageName", package, envir = loadenv)
            if(length(deps)) assign(".Depends", deps, envir = loadenv)
            ## source file into loadenv
            if(file.exists(codeFile)) {
                res <- try(sys.source(codeFile, loadenv,
                                      keep.source = keep.source))
                if(inherits(res, "try-error"))
                    stop(gettextf("unable to load R code in package '%s'",
                                  package),
                         call. = FALSE, domain = NA)
            } else if(verbose)
                warning(gettextf("package '%s' contains no R code",
                                 package), domain = NA)
            ## lazy-load data sets if required
            dbbase <- file.path(which.lib.loc, package, "data", "Rdata")
            if(file.exists(paste0(dbbase, ".rdb")))
                lazyLoad(dbbase, loadenv)
            ## lazy-load a sysdata database if present
            dbbase <- file.path(which.lib.loc, package, "R", "sysdata")
            if(file.exists(paste0(dbbase, ".rdb")))
                lazyLoad(dbbase, loadenv)
            ## now transfer contents of loadenv to an attached frame
            env <- attach(NULL, pos = pos, name = pkgname)
            ## detach does not allow character vector args
            on.exit(do.call("detach", list(name = pkgname)))
            attr(env, "path") <- file.path(which.lib.loc, package)
            ## the actual copy has to be done by C code to avoid forcing
            ## promises that might have been created using delayedAssign().
            .Internal(lib.fixup(loadenv, env))

            ## Do this before we use any code from the package
            bindTranslations(package, pkgpath)

            ## run .First.lib
            if(exists(".First.lib", mode = "function",
                      envir = env, inherits = FALSE)) {
                firstlib <- get(".First.lib", mode = "function",
                                envir = env, inherits = FALSE)
                tt <- try(firstlib(which.lib.loc, package))
                if(inherits(tt, "try-error"))
                    if (logical.return) return(FALSE)
                    else stop(gettextf(".First.lib failed for '%s'",
                                       package), domain = NA)
            }
            if(!is.null(firstlib <- getOption(".First.lib")[[package]])) {
                tt <- try(firstlib(which.lib.loc, package))
                if(inherits(tt, "try-error"))
                    if (logical.return) return(FALSE)
                    else stop(gettextf(".First.lib failed for '%s'",
                                       package), domain = NA)
            }
            ## If there are generics or metadata the package should
            ## depend on methods and so have turned methods dispatch on.
            if(.isMethodsDispatchOn()) {
                nogenerics <- checkNoGenerics(env, package)
                doCache <- !nogenerics || methods:::.hasS4MetaData(env)
            }
            else {
                nogenerics <- TRUE; doCache <- FALSE
            }
            if(warn.conflicts &&
               !exists(".conflicts.OK", envir = env, inherits = FALSE))
                checkConflicts(package, pkgname, pkgpath, nogenerics, env)

            if(doCache)
                methods::cacheMetaData(env, TRUE, searchWhere = .GlobalEnv)
            runUserHook(package, pkgpath)
            on.exit()
	}
	if (verbose && !newpackage)
            warning(gettextf("package '%s' already present in search()",
                             package), domain = NA)

    }
   
	if(!character.only)
	    help <- as.character(substitute(help))
        pkgName <- help[1L]            # only give help on one package
        pkgPath <- .find.package(pkgName, lib.loc, verbose = verbose)
        docFiles <- c(file.path(pkgPath, "Meta", "package.rds"),
                      file.path(pkgPath, "INDEX"))
        if(file.exists(vignetteIndexRDS <-
                       file.path(pkgPath, "Meta", "vignette.rds")))
            docFiles <- c(docFiles, vignetteIndexRDS)
        pkgInfo <- vector(length = 3L, mode = "list")
        readDocFile <- function(f) {
            if(basename(f) %in% "package.rds") {
                txt <- .readRDS(f)$DESCRIPTION
                if("Encoding" %in% names(txt)) {
                    to <- if(Sys.getlocale("LC_CTYPE") == "C") "ASCII//TRANSLIT"else ""
                    tmp <- try(iconv(txt, from=txt["Encoding"], to=to))
                    if(!inherits(tmp, "try-error"))
                        txt <- tmp
                    else
                        warning("'DESCRIPTION' has 'Encoding' field and re-encoding is not possible", call.=FALSE)
                }
                nm <- paste0(names(txt), ":")
                formatDL(nm, txt, indent = max(nchar(nm, "w")) + 3)
            } else if(basename(f) %in% "vignette.rds") {
                txt <- .readRDS(f)
                ## New-style vignette indices are data frames with more
                ## info than just the base name of the PDF file and the
                ## title.  For such an index, we give the names of the
                ## vignettes, their titles, and indicate whether PDFs
                ## are available.
                ## The index might have zero rows.
                if(is.data.frame(txt) && nrow(txt))
                    cbind(basename(gsub("\\.[[:alpha:]]+$", "",
                                        txt$File)),
                          paste(txt$Title,
                                paste0(rep.int("(source", NROW(txt)),
                                       ifelse(txt$PDF != "",
                                              ", pdf",
                                              ""),
                                       ")")))
                else NULL
            } else
            readLines(f)
        }
        for(i in which(file.exists(docFiles)))
            pkgInfo[[i]] <- readDocFile(docFiles[i])
        y <- list(name = pkgName, path = pkgPath, info = pkgInfo)
        class(y) <- "packageInfo"
        return(y)
    }
   
}
