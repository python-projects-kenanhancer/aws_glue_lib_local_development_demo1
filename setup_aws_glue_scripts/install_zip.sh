#!/bin/bash

# Determine the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the os_check.sh script to get the OS detection functions
source "$SCRIPT_DIR/os_check.sh"

function install_zip {
    if is_mac_os || is_linux_os; then
        # Check if zip is already installed
        if ! command -v zip &>/dev/null; then
            echo "Zip is not installed. Installing..."
            if is_mac_os; then
                brew install zip
            elif is_linux_os; then
                sudo apt-get install zip
            fi
        else
            echo "Zip is already installed."
        fi
    elif is_windows_os; then
        # Check if Choco is installed
        if ! command -v choco &>/dev/null; then
            echo "Choco is not installed."
            echo "Run PowerShell as administrator, then run the following command in terminal:"
            echo "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-ObjectSystem.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
            exit 1 # Exit the script since Choco is essential
        else
            # Check if zip is already installed
            if ! command -v zip &>/dev/null; then
                echo "Zip is not installed. Installing..."
                choco install zip
            else
                echo "Zip is already installed."
            fi
        fi
    else
        echo "Unsupported operating system."
    fi
}
