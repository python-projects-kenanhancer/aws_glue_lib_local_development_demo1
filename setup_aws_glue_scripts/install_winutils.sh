#!/bin/bash

# Exit script on any error
set -e

# Install Winutils for Hadoop in Windows OS, run this script in GitBash or Ubuntu WSL.
# After installation completed, you can use Hadoop commands in PowerShell, GitBash, or Ubuntu WSL.

# Determine the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the os_check.sh script to get the OS detection functions
source "$SCRIPT_DIR/os_check.sh"

# Function to check the command success
function check_success {
    local last_exit_code=$?
    local success_message=$1
    local error_message=$2
    local action=${3:-"exit"}

    if [ $last_exit_code -ne 0 ]; then
        echo "Error: $error_message with exit code $last_exit_code."
        if [ "$action" = "exit" ]; then
            exit 1
        else
            return $last_exit_code
        fi
    else
        if [ ! -z "$success_message" ]; then
            echo "Success: $success_message"
        fi
    fi
}

# Initialize environment based on OS
function initialize_environment {
    if [ -z "$HADOOP_HOME" ]; then
        echo "Error: HADOOP_HOME environment variable is not set."
        exit 1
    fi

    HADOOP_DIR="$HADOOP_HOME"
    WINUTILS_URL="https://github.com/steveloughran/winutils/raw/master/hadoop-3.0.0/bin/winutils.exe"
    WINUTILS_DEST="$HADOOP_DIR/bin/winutils.exe"

    echo "Winutils URL: ${WINUTILS_URL}"
    echo "Hadoop Directory: ${HADOOP_DIR}"
    echo "Destination Path: ${WINUTILS_DEST}"
    echo "***********************************************"
}

# Functions
function download_winutils {
    # Check if the Winutils binary already exists
    if [ -f "$WINUTILS_DEST" ]; then
        echo "Winutils binary already exists at $WINUTILS_DEST."
        return
    fi

    echo "Downloading Winutils..."
    curl -L -o "$WINUTILS_DEST" "$WINUTILS_URL" || {
        echo "Error: Failed to download Winutils. Please check your network connection and ensure the URL is accessible."
        exit 1
    }
    check_success "Winutils downloaded successfully." "Failed to download Winutils. Please check your network connection and ensure the URL is accessible. If the issue persists, verify proxy settings or contact network support." "exit"

    # Verify the downloaded file has a reasonable size
    file_size=$(stat -c%s "$WINUTILS_DEST")
    if [ $file_size -lt 100000 ]; then
        echo "Error: Downloaded file size is too small. Please check the URL or the downloaded file."
        echo "File size detected: $file_size"
        echo "Contents of the file:"
        head -n 20 "$WINUTILS_DEST"
        rm -f "$WINUTILS_DEST" # Remove the invalid file
        exit 1
    fi
}

function verify_installation {
    echo "Verifying Winutils installation..."
    winutils_version=$("$WINUTILS_DEST" 2>&1 | grep "Usage")
    if [[ "$winutils_version" == *"Usage"* ]]; then
        echo "Winutils is installed correctly."
    else
        echo "Winutils installation verification failed."
    fi
}

function winutils_installed {
    if [ -f "$WINUTILS_DEST" ]; then
        return 0
    else
        return 1
    fi
}

function cleanup {
    # Cleanup (if needed)
    echo "Cleaning up..."
    # Example: remove downloaded files or temporary directories
    # rm -f "$WINUTILS_ARCHIVE"
}

function install_winutils {
    initialize_environment

    if winutils_installed; then
        echo "Winutils is already installed at ${WINUTILS_DEST}."
        verify_installation
    else
        echo "Winutils is not installed. Proceeding with installation..."
        download_winutils
        verify_installation
        cleanup

        echo "Winutils Installation is completed."
    fi
}

# Execute install_winutils if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_winutils
fi
