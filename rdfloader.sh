#!/bin/bash

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

usage()
{
    cat << EOF
usage: $SELF [OPTIONS] -f [file]

Loads RDF into Virtuoso. 

OPTIONS:
-d URI  The dataset that will be replaced by this data.
-k int  Number of (hidden) named graphs to keep for this dataset. 
-i      Rebuild text index. 
-v      Make newest visible for user 'nobody', hide older graphs for dataset.
-g URI  The named graph data is to be loaded in.
-e      Erase the graph before loading data to it.

EXAMPLES:

 $SELF -g http://data.bibliotheken.nl/persons/2023-r01/ -f NTA.rdf -v -i
    Data is loaded in the given named graph (-g). It will be made visible (-v) by setting 
    the permissions for user 'nobody' for this graph to '1'.
    The Virtuoso text index (-i) will be rebuild.

$SELF -d http://data.bibliotheken.nl/id/dataset/persons -f NTA.rdf -v -i
    This will make NTA.rdf visible as 'dataset' referenced by the URI
    http://data.bibliotheken.nl/id/dataset/persons and loaded in a new
    named graph.
    A prerequisite is that such a 'dataset' exists. 
    
    The relation between an entity ?s and a dataset ?d is assumed to be defined by:
        ?s $SUBJECT_DATASET_RELATION ?d .
    This may be changed in 'src/settings.sh'.
     
    The URI of the named graph will be based on the existing named graph URIs for this
    dataset.  A URI pattern for the graph name ending in /{year}-r{two digit sequence}/ is 
    expected. Previously loaded named graph for this dataset are hidden. 
    As a default, $NUM_KEEP_GRAPHS are kept, older named graphs are deleted. 
    Visibility of the loaded graph is set to '1' for user 'nobody'.
    
Before you start, make sure that 'src/settings' has the correct paths for
the isql command and the Virtuoso load_dir.    
    

EOF
    exit
}

read_commandline_parameters()
{
    local option

    DATASET_URI=''
    GRAPH_URI=''
    
    while getopts "hf:d:g:k:i:v" option ; do
        case $option in
            h)  usage
                ;;
            f)  FILE="$OPTARG"
                ;;
            d)  DATASET_URI="$OPTARG"
                ;;
            g)  GRAPH_URI="$OPTARG"
                ;;
            k)  NUM_KEEP_GRAPHS="$OPTARG"
                ;;
            i)  REINDEX="true"
                ;;
            v)  SETVISIBILITY="true"
                ;;
            e)  ERASE="true"
                ;;
            ?)  usage
                ;;
        esac
    done
}

check_parameter_validity()
{
    if [ -z "$FILE" ] ; then
        echo "Error. No filename given. Please use -f to supply a file to load. Exiting."
        exit 1
    fi
    if [ ! -f "$FILE" ] ; then
        echo "Error. FIle $FILE not found. Exiting."
        exit 1
    fi
    if [ -z "$DATASET_URI" ] && [ -z "$GRAPH_URI" ] ; then
        echo "Error. Please provide the URI of a named graph (-g) or dataset (-d). Exiting."
        exit 1
    elif [ ! -z "$DATASET_URI" ] && [ ! -z "$GRAPH_URI" ] ; then
        echo "Error. Please provide either the URI of a named graph (-g) or of a dataset (-d), not both. Exiting."
        exit 1
    fi
}

# preparations:
check_requirements
read_commandline_parameters "$@"
check_parameter_validity

# determine what graph to use:
if [ -z "$GRAPH_URI" ] ; then
    # obtain $GRAPH_URI and other graphs used for $DATASET_URI
    all_graphs_for_dataset "$DATASET_URI" && ALL_GRAPHS="$RETURNVALUE"
    get_last_graph "$ALL_GRAPHS" && LAST_GRAPH="$RETURNVALUE"
    get_new_graph "$LAST_GRAPH" && GRAPH_URI="$RETURNVALUE"
fi

#prepare load:
copy_file_to_loaddir "$FILE" && FILE_IN_LOADDIR="$RETURNVALUE"
clear_loadlist
put_file_and_graph_on_loadlist "$FILE_IN_LOADDIR" "$GRAPH_URI"

if [ "$ERASE" = "true" ] ; then
    erase_graph "$GRAPH_URI"
fi

# load:
load_rdf

# clean up:

[ "$SETVISIBILITY" = "true" ] && show_graph "$GRAPH_URI" ;

if [ ! -z "$ALL_GRAPHS" ] ; then
    # manage all named graphs when load based on $DATASET_URI
    [ "$SETVISIBILITY" = "true" ] && hide_graph "$LAST_GRAPH"
    delete_graphs "$ALL_GRAPHS" "$NUM_KEEP_GRAPHS"
fi

if [ "$REINDEX" = "true" ] ; then
    rebuild_textindex
fi

msg "Done."

