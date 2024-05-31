#!/bin/bash

# Determine the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run install_zip.sh in a subshell
(
    source "$SCRIPT_DIR/install_zip.sh"
    install_zip
)

# Run setup_virtual_env.sh in a subshell
(
    source "$SCRIPT_DIR/setup_virtual_env.sh"
    setup_virtual_env
)

# Run install_apache_maven.sh in a subshell
(
    source "$SCRIPT_DIR/install_apache_maven.sh"
    install_apache_maven
)

# Run install_apache_spark.sh in a subshell
(
    source "$SCRIPT_DIR/install_apache_spark.sh"
    install_apache_spark
)

# Run install_apache_hadoop.sh in a subshell
(
    source "$SCRIPT_DIR/install_apache_hadoop.sh"
    install_apache_hadoop
)

# Run install_apache_spark.sh in a subshell
(
    source "$SCRIPT_DIR/install_aws_glue_libs.sh"
    install_aws_glue_libs
)

# export PYTHONPATH="${AWS_GLUE_HOME}:${AWS_GLUE_HOME}/PyGlue.zip:$SPARK_HOME/python/lib/pyspark.zip:$SPARK_HOME/python/lib/py4j-0.10.9.5-src.zip:$SPARK_HOME/python/"
# export PYSPARK_PYTHON="/c/Users/0546dr/Documents/rdr_solution_v3/convert_csv_to_parque_glue_job/.venv/Scripts/python"
