#!/bin/bash

# Determine the directory of this script
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLUE_SCRIPT_DIR="$ROOT_DIR/setup_aws_glue_scripts"

# Run setup_virtual_env.sh in a subshell
(
    source "$GLUE_SCRIPT_DIR/setup_virtual_env.sh"
    setup_virtual_env
)

# Function to stop any running Jupyter servers
function stop_existing_jupyter() {
    echo "Stopping any existing Jupyter Notebook servers..."
    SERVER_LIST=$(pipenv run jupyter notebook list | grep -o 'http://[^ ]*' | awk -F: '{print $3}' | awk -F/ '{print $1}')
    for PORT in $SERVER_LIST; do
        echo "Stopping Jupyter server on port $PORT"
        pipenv run jupyter notebook stop $PORT
    done
}

# Function to start Jupyter server
function start_jupyter() {
    echo "Starting Jupyter Notebook server..."
    pipenv run jupyter notebook --no-browser >jupytzer_output.log 2>&1 &
    JUPYTER_PID=$!
    sleep 8
    JUPYTER_URL=$(grep -o 'http://127.0.0.1:[0-9]*/[^ ]*' jupyter_output.log | head -n 1)
    echo "Jupyter Server URL: $JUPYTER_URL"
    echo $JUPYTER_URL | pbcopy
    echo "Jupyter Server URL has been copied to the clipboard."
}

# Function to stop Jupyter server
function stop_jupyter() {
    if [[ -n "$JUPYTER_PID" ]]; then
        echo "Stopping Jupyter Notebook server..."
        kill $JUPYTER_PID
        echo "Jupyter Notebook server stopped."
    else
        echo "No Jupyter server PID found."
    fi
}

# Function to stop watchmedo process
function stop_watchmedo() {
    if [[ -n "$WATCHMEDO_PID" ]]; then
        echo "Stopping watchmedo process..."
        kill $WATCHMEDO_PID
        echo "watchmedo process stopped."
    else
        echo "No watchmedo PID found."
    fi
}

# Ensure that both Jupyter server and watchmedo process are stopped on exit
trap stop_jupyter EXIT
trap stop_watchmedo EXIT

# Step 1: Stop any existing Jupyter servers
stop_existing_jupyter

# Step 2: Activate pipenv environment and run the watchmedo command
echo "Starting watchmedo to convert notebooks to scripts..."
pipenv run watchmedo shell-command --patterns='*.ipynb' --command='pipenv run jupyter nbconvert --to script ${watch_src_path}' --recursive . &
WATCHMEDO_PID=$!

# Step 3: Start Jupyter server
start_jupyter

# Step 4: Open VSCode with the notebook file in the glue_job directory
code ./glue_job/*.ipynb

# Step 5: Instructions for setting up the kernel
echo "From the Command Palette (Ctrl+Shift+P), select 'Notebook: Select Notebook Kernel'."
echo "Then select 'Select Another Kernel...'."
echo "Next, select 'Existing Jupyter Server...'."
echo "Paste the Jupyter Server URL (it is copied to your clipboard)."
echo "Press Enter, then press Enter again, then select AWS Glue Jupyter Local"

# Wait for user input to stop the Jupyter server
read -p "Press Enter to stop the Jupyter server and watchmedo process..."

# Stop Jupyter server
stop_jupyter

# Stop watchmedo process
stop_watchmedo

echo "All steps completed."
