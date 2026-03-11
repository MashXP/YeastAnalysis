#!/bin/bash

# Source conda initialization to make mamba/conda available
# This path was found in your miniforge3 installation
CONDA_PROFILE="/home/mashxp/miniforge3/etc/profile.d/conda.sh"

if [ -f "$CONDA_PROFILE" ]; then
    source "$CONDA_PROFILE"
else
    echo "Warning: Conda profile not found at $CONDA_PROFILE"
fi

echo "Installing VS Code R integration packages (languageserver, httpgd) via mamba..."

mamba install -n yeast_downstream -y -c conda-forge \
    r-languageserver \
    r-httpgd

if [ $? -eq 0 ]; then
    echo "Successfully installed packages."
else
    echo "Error: Installation failed."
    exit 1
fi
