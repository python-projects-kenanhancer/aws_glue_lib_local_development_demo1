#!/bin/bash

# Exit script on any error
set -e

# Install Apache Maven in Windows OS, run this script in GitBash or Ubuntu WSL.
# After installation completed, use can use mvn commands in PowerShell, GitBash or Ubuntu WSL.

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
  MAVEN_VERSION="3.6.0"
  MAVEN_NAME="apache-maven-${MAVEN_VERSION}-bin"
  MAVEN_ARCHIVE="${MAVEN_NAME}.tar.gz"
  MAVEN_URL="https://aws-glue-etl-artifacts.s3.amazonaws.com/glue-common/${MAVEN_ARCHIVE}"

  if is_mac_os || is_linux_os; then
    MAVEN_INSTALL_DIR="$HOME/${MAVEN_NAME}"
    PROFILE_PATH=$(determine_shell_profile)
  elif is_windows_os; then
    MAVEN_INSTALL_DIR="/c/Users/${USERNAME}/${MAVEN_NAME}"
    PROFILE_PATH=$(determine_shell_profile)

    MAVEN_INSTALL_DIR_FOR_POWERSHELL="C:\\Users\\${USERNAME}\\${MAVEN_NAME}"
    POWERSHELL_PROFILE_PATH=$(determine_powershell_profile_path)
  fi

  mkdir -p "$MAVEN_INSTALL_DIR"
  echo "Apache Maven Version: ${MAVEN_VERSION}"
  echo "Installation Directory: ${MAVEN_INSTALL_DIR}"
  echo "Profile Path: ${PROFILE_PATH}"
  echo "PowerShell Profile Path: ${POWERSHELL_PROFILE_PATH}"
  echo "***********************************************"
}

# Functions
function download_maven {
  # Check if the Maven archive already exists
  if [ -f "$MAVEN_ARCHIVE" ]; then
    echo "Maven archive already exists at $MAVEN_ARCHIVE."
    return
  fi

  echo "Downloading Maven ${MAVEN_VERSION}..."
  curl -o "$MAVEN_ARCHIVE" "$MAVEN_URL"
  mv "$MAVEN_ARCHIVE" "$MAVEN_INSTALL_DIR"
  check_success "Apache Maven downloaded successfully." "Failed to download Maven. Please check your network connection and ensure the URL is accessible. If the issue persists, verify proxy settings or contact network support." "exit"
}

function extract_maven {
  echo "Extracting Maven ${MAVEN_VERSION}..."
  tar -xvzf "$MAVEN_INSTALL_DIR/$MAVEN_ARCHIVE" -C "$MAVEN_INSTALL_DIR" --strip-components=1
  check_success "Apache Maven ${MAVEN_VERSION} extracted successfully." "Failed to extract Maven. Please check the archive file integrity and permissions." "exit"
}

function set_environment_variables {
  echo "Setting environment variables in Shell..."
  if ! grep -q "MAVEN_HOME=\"${MAVEN_INSTALL_DIR}\"" "$PROFILE_PATH"; then
    echo "Setting environment variables..."
    echo "export MAVEN_HOME=\"${MAVEN_INSTALL_DIR}\"" >>"$PROFILE_PATH"
    echo "export PATH=\"\${MAVEN_HOME}/bin:\$PATH\"" >>"$PROFILE_PATH"
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

  if ! grep -q "MAVEN_HOME" "$POWERSHELL_PROFILE_PATH"; then
    echo "\$env:MAVEN_HOME = '${MAVEN_INSTALL_DIR_FOR_POWERSHELL}'" >>"$POWERSHELL_PROFILE_PATH"
    echo "\$env:PATH = \"\$env:MAVEN_HOME\\bin;\" + \$env:PATH" >>"$POWERSHELL_PROFILE_PATH"
    echo "Environment variables added to PowerShell profile."
  else
    echo "Environment variables already set in PowerShell."
  fi
}

function verify_installation {
  echo "Verifying Maven installation..."
  mvn -version
}

function maven_installed {
  if ! command -v mvn &>/dev/null; then
    return 1
  else
    return 0
  fi
}

function cleanup {
  # Cleanup
  echo "Cleaning up..."
  rm -rf "apache-maven-${MAVEN_VERSION}"
  rm -f "$MAVEN_ARCHIVE"
}

function install_apache_maven {
  initialize_environment

  if maven_installed; then
    echo "Apache Maven ${MAVEN_VERSION} is already installed at ${MAVEN_INSTALL_DIR}."
    verify_installation
  else
    echo Apache "Maven ${MAVEN_VERSION} is not installed. Proceeding with installation..."
    download_maven
    extract_maven
    set_environment_variables
    if is_windows_os; then
      set_powershell_environment_variables
    fi
    cleanup
    if maven_installed; then
      verify_installation
    fi

    echo "Apache Maven Installation is completed."
  fi
}

# Execute install_apache_maven if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_apache_maven
fi
