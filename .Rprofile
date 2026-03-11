local({
  # Ensure VS Code R extension requirements are met
  if (Sys.getenv("TERM_PROGRAM") == "") {
    Sys.setenv(TERM_PROGRAM = "vscode")
  }
  Sys.unsetenv("RSTUDIO")

  # Temporarily mock interactive() to TRUE if needed, 
  # as VS Code R terminal might appear non-interactive during startup
  masked_interactive <- FALSE
  if (!interactive()) {
    assign("interactive", function() TRUE, envir = globalenv())
    masked_interactive <- TRUE
  }

  # Source the VS Code R init script
  init_path <- file.path(Sys.getenv("HOME"), ".vscode-R", "init.R")
  if (file.exists(init_path)) {
    tryCatch({
      source(init_path)
    }, error = function(e) {
      message("Error sourcing VS Code R init script: ", e$message)
    })
  } else {
    message("VS Code R init script not found at: ", init_path)
  }

  # Clean up mocked interactive function
  if (masked_interactive) {
    rm("interactive", envir = globalenv())
  }
})
