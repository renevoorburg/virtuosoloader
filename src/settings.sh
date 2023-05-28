#!/bin/bash


# isql, used to comnunicate with virtuoso, make sure to append VERBOSE=OFF "":
ISQL="docker exec --interactive my-virtuoso isql-v VERBOSE=OFF"

# load_dir used by virtuoso ld_dir command:
LOADDIR="/Users/rene/data/virtuoso"

# number of older graphs to keep, after loading a new one (MINIMUM = 1 !):
NUM_KEEP_GRAPHS=2

SUBJECT_DATASET_RELATION="<http://schema.org/mainEntityOfPage>/<http://schema.org/isPartOf>"
