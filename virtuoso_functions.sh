#!/bin/bash


msg()
{
    if $VERBOSE ; then
        ((MSG_COUNTER++))
        echo "$MSG_COUNTER. $1"
    fi
}

clear_loadlist()
{
    echo "delete from DB.DBA.load_list;" | $ISQL > /dev/null

    local res=$(echo "select count(*) from DB.DBA.load_list;" | $ISQL | tail -n 2 | head -n 1)

    if [ ! $res -eq 0 ] ; then
        echo "Error: Loadlist not emptied."
        exit 1
    fi
    msg "Cleared the Virtuoso loadlist."
}

copy_file_to_loaddir()
{
    local file="$1"
    local basename=$(basename $file)

    if [ !  -f "$file" ] ; then
        echo "Error: File $file not found. Exiting."
        exit 1
    fi
    cp "$file" "$LOADDIR/" 2> /dev/null
    if [ ! $? -eq 0 ]; then
        echo "Error: File $file could not be copied to $LOADDIR. Exiting."
        exit 1
    fi
    msg "Copied $file to $LOADDIR/$basename (Virtuoso loaddir)."

    RETURNVALUE="$LOADDIR/$basename"
}

put_file_and_graph_on_loadlist()
{
    local file="$1"
    local graph="$2"
    local basename=$(basename $file)

    if [ !  -f "$file" ] ; then
        echo "Error: File $file not found. Exiting."
        exit 1
    fi
    if [ -z "$graph" ] ; then
        echo "Error: Graph not specified. Exiting."
        exit 1
    fi

    echo "ld_dir ('.', '$basename', '$graph');" | $ISQL > /dev/null
    # echo "ld_dir ('$LOADDIR', '$basename', '$graph');" | $ISQL > /dev/null

    local res="$(echo "select ll_file from DB.DBA.load_list where ll_error IS NULL;" | $ISQL | tail -n 2 | head -n 1)"

    if [ ! "$res" == "./$basename" ] ; then ######
        echo "Error: File $file not on loadlist. Exiting."
        exit 1
    fi

    msg "Placed $file on the Virtuoso loadlist for graph $graph."
}

load_rdf()
{
    msg "Loading the data into Virtuoso...(this may take some time)"
    echo "rdf_loader_run();" | $ISQL > /dev/null 2>&1

    local res=$(echo "select count(*) from DB.DBA.load_list where ll_error IS NOT NULL;" | $ISQL | tail -n 2 | head -n 1)
    echo "checkpoint_interval(120);" | $ISQL > /dev/null 2>&1

    if [ ! $res -eq 0 ] ; then
        echo "Error: An error occured when processing the loadlist. Exiting."
        exit 1
    fi
    msg "Data has been loaded!"

    msg "Running a checkpoint...(this may take some time)"
    echo "checkpoint;" | $ISQL > /dev/null 2>&1

}

all_graphs_for_dataset()
{
    local dataset_uri="$1"

    RETURNVALUE="$(echo "sparql select distinct ?g where { graph ?g { [] $SUBJECT_DATASET_RELATION <${dataset_uri}> . }};" | $ISQL | tail -n +5 | $HEADCMD -n -1)"

    
    msg "Collected named graphs relevant for this dataset ($(echo "$RETURNVALUE" | wc -l | awk '{print $1}'))."
}

get_last_graph()
{
    local graphs="$1"
    local last="$(echo "$graphs" | egrep '.*/[0-9]{4}-r[0-9]{2}/$' | sort | tail -n 1)"

    if [ -z "$last" ] ; then
        echo "Error. Could not determine graph. Exiting."
        exit 1
    fi

   RETURNVALUE="$last"
}

get_new_graph()
{
    local last="$1"
    local this_year="$(date +%Y)"

    local urlbase="$(echo "$last" | perl -pe 's@/[0-9]{4}-r[0-9]{2}/$@/@')"
    local year="$(echo "$last" | perl -pe 's@.*/([0-9]{4})-r[0-9]{2}/$@\1@')"
    local rel=$(echo "$last" | perl -pe 's@.*/[0-9]{4}-r([0-9]{2})/$@\1@')

    local nextrel="01"

    if [ "$year" == "$this_year" ] ; then
        # increase nextrel, after removing optional leading space:
        nextrel=$(($(echo "$rel" | perl -pe 's@^0@@')+1))
        if [ $nextrel -lt 10 ] ; then
            nextrel="0${nextrel}"
        fi
    fi

    RETURNVALUE="${urlbase}${this_year}-r${nextrel}/"
}

hide_graph()
{
    local graph="$1"
    echo "DB.DBA.RDF_GRAPH_USER_PERMS_SET ('$graph', 'nobody', 0);" | $ISQL > /dev/null 2>&1

    msg "Made graph $graph invisibile for online users."
}

show_graph()
{
    local graph="$1"
    echo "DB.DBA.RDF_GRAPH_USER_PERMS_SET ('$graph', 'nobody', 1);" | $ISQL > /dev/null 2>&1

    msg "Made graph $graph visibile for online users."
}

delete_graphs()
{
    local graphs="$1"
    local num_keep_graphs="-$2"

    for g in `echo "$graphs" | sort | $HEADCMD -n $num_keep_graphs` ; do
        msg "Deleting graph $g ... (this may take some time)."
        echo "sparql drop silent graph <$g>;" | $ISQL > /dev/null 2>&1
    done

}

rebuild_textindex()
{
    msg "Rebuilding text index... (this may take some time)."
    echo "DB.DBA.RDF_OBJ_FT_RECOVER (); COMMIT WORK;" | $ISQL > /dev/null 2>&1
}

