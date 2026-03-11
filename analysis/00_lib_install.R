# 00_lib_install.R
# Goal: Check for and install all required R packages for the RNA-seq workflow

# 1. Define required packages
cran_packages <- c("tidyverse", "pheatmap", "BiocManager")
bioc_packages <- c("DESeq2", "clusterProfiler", "org.Sc.sgd.db", "apeglm", "EnhancedVolcano")

# 2. Function to install missing CRAN packages
install_cran <- function(pkgs) {
  new_pkgs <- pkgs[!(pkgs %in% installed.packages()[, "Package"])]
  if (length(new_pkgs)) {
    message("Installing missing CRAN packages: ", paste(new_pkgs, collapse = ", "))
    install.packages(new_pkgs, repos = "https://cloud.r-project.org")
  } else {
    message("All CRAN packages are already installed.")
  }
}

# 3. Function to install missing Bioconductor packages
install_bioc <- function(pkgs) {
  new_pkgs <- pkgs[!(pkgs %in% installed.packages()[, "Package"])]
  if (length(new_pkgs)) {
    message("Installing missing Bioconductor packages: ", paste(new_pkgs, collapse = ", "))
    BiocManager::install(new_pkgs, update = FALSE, ask = FALSE)
  } else {
    message("All Bioconductor packages are already installed.")
  }
}

# 4. Execute installation
install_cran(cran_packages)
install_bioc(bioc_packages)

message("Library check and installation complete.")
