#!/bin/bash

# Functions for OS detection
function is_mac_os {
    [[ "$OSTYPE" == "darwin"* ]]
}

function is_linux_os {
    [[ "$OSTYPE" == "linux-gnu"* ]]
}

function is_windows_os {
    [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]
}
