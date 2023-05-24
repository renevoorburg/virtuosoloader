#!/bin/bash


check_requirements()
{
    # TODO make this work using a mac
    if [ "$(uname)" != "Darwin" ] ; then 
        local cron=$(pstree -s $$ | grep -q cron && echo true || echo false)
        local screen=$(pstree -s $$ | grep -q screen && echo true || echo false)

        if [ "$cron" == "false" ] && [ "$screen" == "false" ] ; then
            echo "Error. This script must be run either from cron or in a screen session. Exiting"
            exit 1
        fi
        HEADCMD="head"
    else 
        # brew install coreutils :
        HEADCMD="ghead"
    fi
}
