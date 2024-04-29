#!/bin/bash

# displays the loadlist in Virtuoso

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

echo "select * from DB.DBA.load_list;" | $ISQL