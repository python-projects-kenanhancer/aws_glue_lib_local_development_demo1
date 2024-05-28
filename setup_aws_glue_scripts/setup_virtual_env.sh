#!/bin/bash

# Determine the parent directory of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Check if virtual environment exists and activate it
function setup_virtual_env {
    VENV_DIR="$PARENT_DIR/.venv"

    if [ ! -d "$VENV_DIR" ]; then
        echo "Python Virtual Environment not found. Creating..."
        export PIPENV_VENV_IN_PROJECT=true
        pipenv --python "$(pyenv which python)"
        pipenv install --dev
    fi

    echo "Activating Python Virtual Environment..."

    # Determine the correct path for the activate script
    if [ -f "$VENV_DIR/bin/activate" ]; then
        source "$VENV_DIR/bin/activate" # Unix-like systems
    elif [ -f "$VENV_DIR/Scripts/activate" ]; then
        source "$VENV_DIR/Scripts/activate" # Windows
    else
        echo "Error: Could not find the activate script in the virtual environment."
        exit 1
    fi
}
