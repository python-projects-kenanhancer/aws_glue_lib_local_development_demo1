#!/bin/bash

# Exit script on any error
# set -e

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
    AWS_GLUE_LIBS_NAME="aws-glue-libs"
    AWS_GLUE_LIBS_URL="https://github.com/awslabs/aws-glue-libs.git"

    if is_mac_os || is_linux_os; then
        AWS_GLUE_LIBS_INSTALL_DIR="$HOME/${AWS_GLUE_LIBS_NAME}"
        PROFILE_PATH=$(determine_shell_profile)
    elif is_windows_os; then
        AWS_GLUE_LIBS_INSTALL_DIR="/c/Users/${USERNAME}/${AWS_GLUE_LIBS_NAME}"
        PROFILE_PATH=$(determine_shell_profile)

        AWS_GLUE_LIBS_INSTALL_DIR_FOR_POWERSHELL="C:\\Users\\${USERNAME}\\${AWS_GLUE_LIBS_NAME}"
        POWERSHELL_PROFILE_PATH=$(determine_powershell_profile_path)
    fi

    echo "Installation Directory: ${AWS_GLUE_LIBS_INSTALL_DIR}"
    echo "Profile Path: ${PROFILE_PATH}"
    echo "PowerShell Profile Path: ${POWERSHELL_PROFILE_PATH}"
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

# Functions
function clone_aws_glue_libs {
    # Check if the Spark archive already exists
    if [ -d "$AWS_GLUE_LIBS_NAME" ]; then
        echo "$AWS_GLUE_LIBS_NAME archive already exists at $AWS_GLUE_LIBS_NAME."
        return
    fi

    echo "Cloning aws-glue-libs repository..."
    git clone $AWS_GLUE_LIBS_URL
    check_success "aws-glue-libs repository is cloned successfully." "Failed to clone aws-glue-libs. Please check your network connection and ensure the URL is accessible. If the issue persists, verify proxy settings or contact network support." "exit"
}

function setup_aws_glue_libs {
    echo "Installing aws_glue_libs to ${AWS_GLUE_LIBS_INSTALL_DIR}..."
    mkdir -p "$AWS_GLUE_LIBS_INSTALL_DIR"
    # chmod u+w "$AWS_GLUE_LIBS_INSTALL_DIR/python"
    # chown $(whoami) "$AWS_GLUE_LIBS_INSTALL_DIR/python"
    mv "$AWS_GLUE_LIBS_NAME"/* "$AWS_GLUE_LIBS_INSTALL_DIR"

    bash $AWS_GLUE_LIBS_INSTALL_DIR/bin/glue-setup.sh

    set_spark_conf

    # cp $AWS_GLUE_LIBS_INSTALL_DIR/jarsv1/AWSGlue*.jar $SPARK_HOME/jars/

    # cp $AWS_GLUE_LIBS_INSTALL_DIR/jarsv1/aws*.jar $SPARK_HOME/jars/

    # If last command fails, display a message and try again
    if [ $? -ne 0 ]; then
        echo "Retrying move operation..."
        sleep 5
        mv "$AWS_GLUE_LIBS_NAME"/* "$AWS_GLUE_LIBS_INSTALL_DIR"
    fi
    check_success "aws-glue-libs installed successfully to ${AWS_GLUE_LIBS_INSTALL_DIR}." "Failed to install aws-glue-libs. Please check directory permissions and disk space." "exit"
}

function set_spark_conf {
    if is_windows_os; then
        SPARK_DIR="C:\\\\Users\\\\${USERNAME}\\\\spark-3.3.0-amzn-1-bin-3.3.3-amzn-0"
        AWS_GLUE_LIBS_DIR="C:\\\\Users\\\\${USERNAME}\\\\${AWS_GLUE_LIBS_NAME}"
        SPARK_CONF_DIR="C:\\Users\\${USERNAME}\\${AWS_GLUE_LIBS_NAME}\\conf"

        if [ ! -d "$SPARK_CONF_DIR" ]; then
            mkdir $SPARK_CONF_DIR
        else
            rm -rf $SPARK_CONF_DIR
            mkdir $SPARK_CONF_DIR
        fi

        echo "spark.driver.extraClassPath ${SPARK_DIR}\\\\jars\\\\*;${AWS_GLUE_LIBS_DIR}\\\\jarsv1\\\\*" >>$SPARK_CONF_DIR\\\\spark-defaults.conf
        echo "spark.executor.extraClassPath ${SPARK_DIR}\\\\jars\\\\*;${AWS_GLUE_LIBS_DIR}\\\\jarsv1\\\\*" >>$SPARK_CONF_DIR\\\\spark-defaults.conf
    fi
}

function set_environment_variables {
    if ! grep -q "AWS_GLUE_HOME=\"${AWS_GLUE_LIBS_INSTALL_DIR}\"" "$PROFILE_PATH"; then
        echo "Setting AWS_GLUE_HOME environment variable..."
        echo "export AWS_GLUE_HOME=\"${AWS_GLUE_LIBS_INSTALL_DIR}\"" >>"$PROFILE_PATH"
        echo "export PATH=\"\${AWS_GLUE_HOME}/bin:\$PATH\"" >>"$PROFILE_PATH"

        source "$PROFILE_PATH"
    else
        echo "AWS_GLUE_HOME environment variable is already set."
    fi

    if ! grep -q "SPARK_CONF_DIR=\"\${AWS_GLUE_HOME}/conf\"" "$PROFILE_PATH"; then
        echo "Setting SPARK_CONF_DIR environment variable..."
        echo "export SPARK_CONF_DIR=\"\${AWS_GLUE_HOME}/conf\"" >>"$PROFILE_PATH"

        source "$PROFILE_PATH"
    else
        echo "SPARK_CONF_DIR environment variable is already set."
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

    if ! grep -q "AWS_GLUE_HOME" "$POWERSHELL_PROFILE_PATH"; then
        echo "\$env:AWS_GLUE_HOME = '${AWS_GLUE_LIBS_INSTALL_DIR_FOR_POWERSHELL}'" >>"$POWERSHELL_PROFILE_PATH"
        echo "\$env:PATH = \"\$env:AWS_GLUE_HOME\\bin;\" + \$env:PATH" >>"$POWERSHELL_PROFILE_PATH"
        echo "Environment variables added to PowerShell profile."
    else
        echo "Environment variables already set in PowerShell."
    fi
}

function configure_jupyter_kernel {
    echo "Configuring Jupyter kernel..."
    install-glue-kernels
    pipenv run python -m ipykernel install --user --name=aws_glue_jupyter_local --display-name "AWS Glue Jupyter Local"

    check_success "Configuring Jupyter kernel"
}

function cleanup {
    # Cleanup
    echo "Cleaning up..."
    rm -rf "$AWS_GLUE_LIBS_NAME"
}

function install_aws_glue_libs {
    initialize_environment

    clone_aws_glue_libs
    setup_aws_glue_libs
    set_environment_variables
    if is_windows_os; then
        set_powershell_environment_variables
    fi
    configure_jupyter_kernel
    cleanup
    set_spark_conf

    echo "$AWS_GLUE_LIBS_NAME Installation is completed."
}

# Execute install_aws_glue_libs if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_aws_glue_libs
fi
