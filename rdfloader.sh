#!/bin/bash

VERBOSE=true

SELF="$0"
FILE="$1"
DATASET_URI="$2"

SCRIPT_DIR=$(dirname "$SELF")

source $SCRIPT_DIR/settings.sh
source $SCRIPT_DIR/functions.sh
source $SCRIPT_DIR/virtuoso_functions.sh

# 
check_requirements

# determine what graph to use:
all_graphs_for_dataset "$DATASET_URI" && ALL_GRAPHS="$RETURNVALUE"
get_last_graph "$ALL_GRAPHS" && LAST_GRAPH="$RETURNVALUE"
get_new_graph "$LAST_GRAPH" && NEW_GRAPH="$RETURNVALUE"

#prepare load:
copy_file_to_loaddir "$FILE" && FILE_IN_LOADDIR="$RETURNVALUE"
clear_loadlist
put_file_and_graph_on_loadlist "$FILE_IN_LOADDIR" "$NEW_GRAPH"

# load:
load_rdf

# clean up:
hide_graph "$LAST_GRAPH"
show_graph "$NEW_GRAPH"
delete_graphs "$ALL_GRAPHS" "$NUM_KEEP_GRAPHS"
rebuild_textindex

msg "Done."


