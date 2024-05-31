#!/bin/bash

# Exit script on any error
set -e

# Install Apache Hadoop in Windows OS, run this script in GitBash or Ubuntu WSL.
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

# Determine shell profile path for Unix-like OS
function determine_shell_profile {
    # Determine and return the appropriate shell profile path
    if [[ "$SHELL" == */zsh ]]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bashrc"
    fi
}

# PowerShell version detection functions
function is_powershell_core_installed {
    # PowerShell 7 (Core)
    command -v pwsh >/dev/null
}

function is_windows_powershell_installed {
    # PowerShell 5
    command -v powershell.exe >/dev/null
}

# Determine the PowerShell profile path for Windows OS
function determine_powershell_profile_path {
    local powershell_profile_path

    if is_powershell_core_installed; then
        # Get PowerShell 7+ profile path
        powershell_profile_path=$(pwsh -Command "Write-Output \$PROFILE.AllUsersAllHosts")
    elif is_windows_powershell_installed; then
        # Get Windows PowerShell 5 profile path
        powershell_profile_path=$(powershell.exe -Command "Write-Output \$PROFILE.AllUsersAllHosts")
    fi

    echo "$powershell_profile_path"
}

# Initialize environment based on OS
function initialize_environment {
    HADOOP_VERSION="3.3.6"
    HADOOP_NAME="hadoop-${HADOOP_VERSION}"
    HADOOP_ARCHIVE="${HADOOP_NAME}.tar.gz"
    HADOOP_URL="https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_ARCHIVE}"

    if is_mac_os || is_linux_os; then
        HADOOP_INSTALL_DIR="$HOME/${HADOOP_NAME}"
        PROFILE_PATH=$(determine_shell_profile)
    elif is_windows_os; then
        HADOOP_INSTALL_DIR="/c/Users/${USERNAME}/${HADOOP_NAME}"
        PROFILE_PATH=$(determine_shell_profile)

        HADOOP_INSTALL_DIR_FOR_POWERSHELL="C:\\Users\\${USERNAME}\\${HADOOP_NAME}"
        POWERSHELL_PROFILE_PATH=$(determine_powershell_profile_path)
    fi

    mkdir -p "$HADOOP_INSTALL_DIR"
    echo "Apache Hadoop Version: ${HADOOP_VERSION}"
    echo "Installation Directory: ${HADOOP_INSTALL_DIR}"
    echo "Profile Path: ${PROFILE_PATH}"
    echo "PowerShell Profile Path: ${POWERSHELL_PROFILE_PATH}"
    echo "***********************************************"
}

# Functions
function download_hadoop {
    # Check if the Hadoop archive already exists
    if [ -f "$HADOOP_ARCHIVE" ]; then
        echo "Hadoop archive already exists at $HADOOP_ARCHIVE."
        return
    fi

    echo "Downloading Hadoop ${HADOOP_VERSION}..."
    curl -o "$HADOOP_ARCHIVE" "$HADOOP_URL"
    mv "$HADOOP_ARCHIVE" "$HADOOP_INSTALL_DIR"
    check_success "Apache Hadoop downloaded successfully." "Failed to download Hadoop. Please check your network connection and ensure the URL is accessible. If the issue persists, verify proxy settings or contact network support." "exit"

    # Verify the downloaded file is a gzip file and has a reasonable size
    file_type=$(file -b "$HADOOP_INSTALL_DIR/$HADOOP_ARCHIVE")
    file_size=$(stat -c%s "$HADOOP_INSTALL_DIR/$HADOOP_ARCHIVE")
    if [[ "$file_type" != *"gzip compressed data"* || $file_size -lt 1000000 ]]; then
        echo "Error: Downloaded file is not in gzip format or the file size is too small. Please check the URL or the downloaded file."
        echo "File type detected: $file_type"
        echo "File size detected: $file_size"
        echo "Contents of the file:"
        head -n 20 "$HADOOP_INSTALL_DIR/$HADOOP_ARCHIVE"
        exit 1
    fi
}

function extract_hadoop {
    echo "Extracting Hadoop ${HADOOP_VERSION}..."
    tar -xvzf "$HADOOP_INSTALL_DIR/$HADOOP_ARCHIVE" -C "$HADOOP_INSTALL_DIR" --strip-components=1
    check_success "Apache Hadoop ${HADOOP_VERSION} extracted successfully." "Failed to extract Hadoop. Please check the archive file integrity and permissions." "exit"
}

function copy_required_jars {
    echo "Copying required JAR files..."
    cp $HADOOP_INSTALL_DIR/share/hadoop/common/lib/slf4j-api-1.7.36.jar $HADOOP_INSTALL_DIR/share/hadoop/common/
    cp $HADOOP_INSTALL_DIR/share/hadoop/common/lib/slf4j-reload4j-1.7.36.jar $HADOOP_INSTALL_DIR/share/hadoop/common/
    check_success "Required JAR files copied successfully." "Failed to copy required JAR files." "exit"
}

function set_environment_variables {
    echo "Setting environment variables in Shell..."
    if ! grep -q "HADOOP_HOME=\"${HADOOP_INSTALL_DIR}\"" "$PROFILE_PATH"; then
        echo "Setting environment variables..."
        echo "export HADOOP_HOME=\"${HADOOP_INSTALL_DIR}\"" >>"$PROFILE_PATH"
        echo "export PATH=\"\${HADOOP_HOME}/bin:\$PATH\"" >>"$PROFILE_PATH"
        echo "export HADOOP_CLASSPATH=\$(cygpath -pw \$(hadoop classpath)):\$HADOOP_CLASSPATH" >>"$PROFILE_PATH"
        source "$PROFILE_PATH"
    else
        echo "Environment variables already set."
    fi
}

function set_powershell_environment_variables() {
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
        echo "\$env:HADOOP_CLASSPATH = [System.IO.Path]::Combine(\$env:HADOOP_HOME, 'share', 'hadoop', 'common', '*') + ';' + [System.IO.Path]::Combine(\$env:HADOOP_HOME, 'share', 'hadoop', 'common', 'lib', '*') + ';' + [System.IO.Path]::Combine(\$env:HADOOP_HOME, 'share', 'hadoop', 'hdfs', '*') + ';' + [System.IO.Path]::Combine(\$env:HADOOP_HOME, 'share', 'hadoop', 'hdfs', 'lib', '*') + ';' + \$env:HADOOP_CLASSPATH" >>"$POWERSHELL_PROFILE_PATH"
        echo "Environment variables added to PowerShell profile."
    else
        echo "Environment variables already set in PowerShell."
    fi
}

function verify_installation {
    echo "Verifying Hadoop installation..."
    hadoop_version=$(hadoop version | grep "Hadoop" | awk '{print $2}')
    echo "Installed Hadoop version: $hadoop_version"

    if [[ "$hadoop_version" == "$HADOOP_VERSION" ]]; then
        echo "Hadoop version is correct: $hadoop_version"
    else
        echo "Hadoop version is incorrect: $hadoop_version. Expected: $HADOOP_VERSION"
    fi
}

function hadoop_installed {
    if ! command -v hadoop &>/dev/null; then
        return 1
    else
        return 0
    fi
}

function cleanup {
    # Cleanup
    echo "Cleaning up..."
    rm -rf "${HADOOP_NAME}"
    rm -f "$HADOOP_ARCHIVE"
}

function install_apache_hadoop {
    initialize_environment

    if hadoop_installed; then
        echo "Apache Hadoop ${HADOOP_VERSION} is already installed at ${HADOOP_INSTALL_DIR}."
        verify_installation
    else
        echo "Apache Hadoop ${HADOOP_VERSION} is not installed. Proceeding with installation..."
        download_hadoop
        extract_hadoop
        copy_required_jars
        set_environment_variables
        if is_windows_os; then
            set_powershell_environment_variables
        fi
        cleanup
        if hadoop_installed; then
            verify_installation
        fi

        echo "Apache Hadoop Installation is completed."
    fi
}

# Execute install_apache_hadoop if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_apache_hadoop
fi
