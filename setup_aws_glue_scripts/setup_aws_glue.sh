#!/bin/bash

# Determine the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the os_check.sh script to get the OS detection functions
source "$SCRIPT_DIR/os_check.sh"

# Run install_zip.sh in a subshell
(
    source "$SCRIPT_DIR/install_zip.sh"
    install_zip
)

# Run install_pbcopy.sh in a subshell
(
    source "$SCRIPT_DIR/install_pbcopy.sh"
    install_pbcopy
)

# Run setup_virtual_env.sh in a subshell
# (
source "$SCRIPT_DIR/setup_virtual_env.sh"
setup_virtual_env
# )

# Run install_apache_maven.sh in a subshell
(
    source "$SCRIPT_DIR/install_apache_maven.sh"
    install_apache_maven
)

# Source the user's profile to update environment variables
source ~/.bashrc

# Run install_apache_spark.sh in a subshell
(
    source "$SCRIPT_DIR/install_apache_spark.sh"
    install_apache_spark
)

# Source the user's profile to update environment variables
source ~/.bashrc

# Run install_winutils.sh in a subshell
if is_windows_os; then
    (
        source "$SCRIPT_DIR/install_winutils.sh"
        install_winutils
    )
fi

# Run install_aws_glue_libs.sh in a subshell
(
    source "$SCRIPT_DIR/install_aws_glue_libs.sh"
    install_aws_glue_libs
)

# Source the user's profile to update environment variables
source ~/.bashrc

# export PYTHONPATH="${AWS_GLUE_HOME}:${AWS_GLUE_HOME}/PyGlue.zip:$SPARK_HOME/python/lib/pyspark.zip:$SPARK_HOME/python/lib/py4j-0.10.9.5-src.zip:$SPARK_HOME/python/"
# export PYSPARK_PYTHON="/c/Users/0546dr/Documents/rdr_solution_v3/convert_csv_to_parque_glue_job/.venv/Scripts/python"
