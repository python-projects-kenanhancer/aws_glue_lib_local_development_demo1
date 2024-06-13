#!/bin/bash

# Exit script on any error
set -e

# Install Winutils for Hadoop in Windows OS, run this script in GitBash or Ubuntu WSL.
# After installation is completed, you can use Hadoop commands in PowerShell, GitBash, or Ubuntu WSL.

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

# Determine shell profile path for Unix-like OS
function determine_shell_profile {
    if [[ "$SHELL" == */zsh ]]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bashrc"
    fi
}

# PowerShell version detection functions
function is_powershell_core_installed {
    command -v pwsh >/dev/null
}

function is_windows_powershell_installed {
    command -v powershell.exe >/dev/null
}

# Determine the PowerShell profile path for Windows OS
function determine_powershell_profile_path {
    local powershell_profile_path

    if is_powershell_core_installed; then
        powershell_profile_path=$(pwsh -Command "Write-Output \$PROFILE.AllUsersAllHosts")
    elif is_windows_powershell_installed; then
        powershell_profile_path=$(powershell.exe -Command "Write-Output \$PROFILE.AllUsersAllHosts")
    fi

    echo "$powershell_profile_path"
}

# Initialize environment based on OS
function initialize_environment {
    WINUTILS_REPO="https://github.com/steveloughran/winutils"
    HADOOP_NAME="hadoop-3.0.0"

    if is_mac_os || is_linux_os; then
        HADOOP_INSTALL_DIR="$HOME/${HADOOP_NAME}"
        PROFILE_PATH=$(determine_shell_profile)
    elif is_windows_os; then
        USERNAME=$USERNAME
        HADOOP_INSTALL_DIR="/c/Users/${USERNAME}/${HADOOP_NAME}"
        PROFILE_PATH=$(determine_shell_profile)

        HADOOP_INSTALL_DIR_FOR_POWERSHELL="C:\\Users\\${USERNAME}\\${HADOOP_NAME}"
        POWERSHELL_PROFILE_PATH=$(determine_powershell_profile_path)
    fi

    WINUTILS_DIR="$SCRIPT_DIR/winutils"
    TEMP_HADOOP_DIR="$WINUTILS_DIR/$HADOOP_NAME"
    HADOOP_HOME="$HADOOP_INSTALL_DIR"

    echo "Winutils Repository: ${WINUTILS_REPO}"
    echo "Temporary Hadoop Directory: ${TEMP_HADOOP_DIR}"
    echo "Hadoop Home Directory: ${HADOOP_HOME}"
    echo "Profile Path: ${PROFILE_PATH}"
    echo "PowerShell Profile Path: ${POWERSHELL_PROFILE_PATH}"
    echo "***********************************************"
}

# Functions
function clone_winutils {
    if [ -d "$WINUTILS_DIR" ]; then
        echo "winutils repository already cloned at $WINUTILS_DIR."
        return
    fi

    echo "Cloning winutils repository..."
    git clone "$WINUTILS_REPO" "$WINUTILS_DIR"
    check_success "winutils repository cloned successfully." "Failed to clone winutils repository. Please check your network connection and ensure the URL is accessible." "exit"
}

function move_hadoop {
    if [ -d "$HADOOP_INSTALL_DIR" ]; then
        echo "Hadoop directory already exists at $HADOOP_INSTALL_DIR."
        return
    fi

    echo "Moving hadoop-3.0.0 to $HADOOP_INSTALL_DIR..."
    mv "$TEMP_HADOOP_DIR" "$HADOOP_INSTALL_DIR"
    check_success "Hadoop directory moved successfully." "Failed to move Hadoop directory." "exit"
}

function set_environment_variables {
    echo "Setting environment variables in Shell..."
    if ! grep -q "export HADOOP_HOME=\"$HADOOP_HOME\"" "$PROFILE_PATH"; then
        echo "Setting environment variables..."
        echo "export HADOOP_HOME=\"$HADOOP_HOME\"" >>"$PROFILE_PATH"
        echo "export PATH=\"\$HADOOP_HOME/bin:\$PATH\"" >>"$PROFILE_PATH"
        source "$PROFILE_PATH"
    else
        echo "Environment variables already set."
    fi
}

function set_powershell_environment_variables {
    echo "Setting environment variables in PowerShell..."
    echo "PowerShell Profile Path: ${POWERSHELL_PROFILE_PATH}"

    if [ ! -f "$POWERSHELL_PROFILE_PATH" ]; then
        echo "Creating PowerShell profile..."
        mkdir -p "$(dirname "$POWERSHELL_PROFILE_PATH")"
        touch "$POWERSHELL_PROFILE_PATH"
    fi

    if ! grep -q "HADOOP_HOME" "$POWERSHELL_PROFILE_PATH"; then
        echo "\$env:HADOOP_HOME = '${HADOOP_INSTALL_DIR_FOR_POWERSHELL}'" >>"$POWERSHELL_PROFILE_PATH"
        echo "\$env:PATH = \"\$env:HADOOP_HOME\\bin;\" + \$env:PATH" >>"$POWERSHELL_PROFILE_PATH"
        echo "Environment variables added to PowerShell profile."
    else
        echo "Environment variables already set in PowerShell."
    fi
}

function cleanup {
    echo "Cleaning up..."
    rm -rf "$WINUTILS_DIR"
    check_success "Cleanup successful." "Failed to clean up winutils directory." "exit"
}

function verify_installation {
    echo "Verifying winutils installation..."
    if [ -f "$HADOOP_HOME/bin/winutils.exe" ]; then
        winutils_version=$("$HADOOP_HOME/bin/winutils.exe" 2>&1 | grep "Usage")
        if [[ "$winutils_version" == *"Usage"* ]]; then
            echo "winutils is installed correctly."
        else
            echo "winutils installation verification failed."
        fi
    else
        echo "winutils.exe not found in $HADOOP_HOME/bin"
        exit 1
    fi
}

function install_winutils {
    initialize_environment
    clone_winutils
    move_hadoop
    set_environment_variables
    if is_windows_os; then
        set_powershell_environment_variables
    fi
    verify_installation
    cleanup
    echo "winutils Installation is completed."
}

# Execute install_winutils if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_winutils
fi
