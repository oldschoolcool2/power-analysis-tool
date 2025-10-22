# renv activation script
# This script is run automatically when R starts in this project directory

local({

  # the requested version of renv
  version <- "1.0.7"

  # the project directory
  project <- getwd()

  # avoid recursion
  if (!is.na(Sys.getenv("RENV_R_INITIALIZING", unset = NA)))
    return(invisible(TRUE))

  # signal that we're loading renv during R startup
  Sys.setenv("RENV_R_INITIALIZING" = "true")
  on.exit(Sys.unsetenv("RENV_R_INITIALIZING"), add = TRUE)

  # signal that we've consented to use renv
  options(renv.consent = TRUE)

  # load the 'utils' package eagerly -- this ensures that renv shims, which
  # mask 'utils' packages, will come first on the search path
  library(utils, lib.loc = .Library)

  # check to see if renv has already been loaded
  if ("renv" %in% loadedNamespaces()) {

    # if renv has already been loaded, and it's the requested version of renv,
    # nothing to do
    spec <- .getNamespaceInfo(.getNamespace("renv"), "spec")
    if (identical(spec[["version"]], version))
      return(invisible(TRUE))

    # otherwise, unload and attempt to load the correct version of renv
    unloadNamespace("renv")

  }

  # load the project
  tryCatch(renv::load(project), error = function(e) {
    warning(e)
    FALSE
  })

})
