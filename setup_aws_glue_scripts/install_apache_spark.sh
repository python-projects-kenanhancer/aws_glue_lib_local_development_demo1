#!/bin/bash

# Exit script on any error
set -e

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
  SPARK_VERSION="3.3.3-amzn-0"
  SPARK_NAME="spark-3.3.0-amzn-1-bin-${SPARK_VERSION}"
  SPARK_ARCHIVE="${SPARK_NAME}.tgz"
  SPARK_URL="https://aws-glue-etl-artifacts.s3.amazonaws.com/glue-4.0/${SPARK_ARCHIVE}"

  if is_mac_os || is_linux_os; then
    SPARK_INSTALL_DIR="$HOME/${SPARK_NAME}"
    PROFILE_PATH=$(determine_shell_profile)
  elif is_windows_os; then
    SPARK_INSTALL_DIR="/c/Users/${USERNAME}/${SPARK_NAME}"
    PROFILE_PATH=$(determine_shell_profile)

    SPARK_INSTALL_DIR_FOR_POWERSHELL="C:\\Users\\${USERNAME}\\${SPARK_NAME}"
    POWERSHELL_PROFILE_PATH=$(determine_powershell_profile_path)
  fi

  mkdir -p "$SPARK_INSTALL_DIR"
  echo "Apache Spark Version: ${SPARK_VERSION}"
  echo "Installation Directory: ${SPARK_INSTALL_DIR}"
  echo "Profile Path: ${PROFILE_PATH}"
  echo "PowerShell Profile Path: ${POWERSHELL_PROFILE_PATH}"
}

# Functions
function download_spark {
  # Check if the Spark archive already exists
  if [ -f "$SPARK_ARCHIVE" ]; then
    echo "Spark archive already exists at $SPARK_ARCHIVE."
    return
  fi

  echo "Downloading Spark ${SPARK_VERSION}..."
  curl -o "$SPARK_ARCHIVE" "$SPARK_URL"
  mv "$SPARK_ARCHIVE" "$SPARK_INSTALL_DIR"
  check_success "Apache Spark downloaded successfully." "Failed to download Spark. Please check your network connection and ensure the URL is accessible. If the issue persists, verify proxy settings or contact network support." "exit"
}

function extract_spark {
  echo "Extracting Spark ${SPARK_VERSION}..."
  tar -xvzf "$SPARK_INSTALL_DIR/$SPARK_ARCHIVE" -C "$SPARK_INSTALL_DIR" --strip-components=1
  check_success "Apache Spark ${SPARK_VERSION} extracted successfully." "Failed to extract Spark. Please check the archive file integrity and permissions." "exit"
}

function set_environment_variables {
  if ! grep -q "SPARK_HOME=\"${SPARK_INSTALL_DIR}\"" "$PROFILE_PATH"; then
    echo "Setting environment variables..."
    echo "export SPARK_HOME=\"${SPARK_INSTALL_DIR}\"" >>"$PROFILE_PATH"
    echo "export PATH=\"\${SPARK_HOME}/bin:\$PATH\"" >>"$PROFILE_PATH"
    source "$PROFILE_PATH"
  else
    echo "Environment variables already set."
  fi
}

function set_powershell_environment_variables {
  echo "PowerShell Profile Path: ${POWERSHELL_PROFILE_PATH}"
  echo "Setting environment variables in PowerShell..."

  if [ ! -f "$POWERSHELL_PROFILE_PATH" ]; then
    echo "Creating PowerShell profile..."
    mkdir -p "$(dirname "$POWERSHELL_PROFILE_PATH")"
    touch "$POWERSHELL_PROFILE_PATH"
  fi

  if ! grep -q "SPARK_HOME" "$POWERSHELL_PROFILE_PATH"; then
    echo "\$env:SPARK_HOME = '${SPARK_INSTALL_DIR_FOR_POWERSHELL}'" >>"$POWERSHELL_PROFILE_PATH"
    echo "\$env:PATH = \"\$env:SPARK_HOME\\bin;\" + \$env:PATH" >>"$POWERSHELL_PROFILE_PATH"
    echo "Environment variables added to PowerShell profile."
  else
    echo "Environment variables already set in PowerShell."
  fi
}

function verify_installation {
  echo "Verifying Apache Spark installation..."
  # pyspark --version
}

function spark_installed {
  if [ -d "$SPARK_INSTALL_DIR" ] && [ -x "$SPARK_INSTALL_DIR/bin/spark-shell" ]; then
    return 0
  else
    return 1
  fi
}

function cleanup {
  # Cleanup
  echo "Cleaning up..."
  rm -rf "spark"
  rm -f "$SPARK_ARCHIVE"
}

function install_apache_spark {
  initialize_environment

  if spark_installed; then
    echo "Apache Spark ${SPARK_VERSION} is already installed at ${SPARK_INSTALL_DIR}."
    verify_installation
  else
    echo "Apache Spark ${SPARK_VERSION} is not installed. Proceeding with installation..."
    download_spark
    extract_spark
    set_environment_variables
    if is_windows_os; then
      set_powershell_environment_variables
    fi
    cleanup
    verify_installation

    echo "Apache Spark Installation is completed."
  fi
}

# Execute install_apache_spark if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_apache_spark
fi
