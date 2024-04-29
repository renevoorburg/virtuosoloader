#!/bin/bash

# makes a graph visible in Virtuoso to user "nobody"

VERBOSE=true
SELF="$0"
SCRIPT_DIR=$(dirname "$SELF")

source "$SCRIPT_DIR/src/settings.sh"
# allow  use of a separate file for local settings:
if [ -f "$SCRIPT_DIR/src/settings_local.sh" ] ; then
    source "$SCRIPT_DIR/src/settings_local.sh"
fi
source "$SCRIPT_DIR/src/functions.sh"
source "$SCRIPT_DIR/src/virtuoso_functions.sh"

show_graph "$1"