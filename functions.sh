#!/bin/bash


check_requirements() {

    local cron=$(pstree -s "$SELF" | grep -q cron && echo true || echo false)
    local screen=$(pstree -s "$SELF" | grep -q screen && echo true || echo false)

    if [ "$cron" == "false" ] && [ "$screen" == "false" ] ; then
        echo "Error. This script must be run either from cron or in a screen session. Exiting"
        exit 1
    fi
}
