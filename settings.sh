#!/bin/bash


# isql, used to comnunicate with virtuoso:
ISQL="docker exec -it my-virtuoso isql-v VERBOSE=OFF"

# load_dir used by virtuoso ld_dir command:
LOADDIR="/Users/rene/data/virtuoso/loaddir"

# number of older graphs to keep, after loading a new one (MINIMUM = 1 !):
NUM_KEEP_GRAPHS=2