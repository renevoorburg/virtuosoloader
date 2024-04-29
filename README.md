# virtuosoloader

A tool and set of shell based functions to make it easier to load RDF into the Virtuoso Open Source (VOS) triple store.

	usage: ./rdfloader [OPTIONS] -f [file]

	OPTIONS:
	-d URI  The dataset that will be replaced by this data.
	-k int  Number of (hidden) named graphs to keep for this dataset.
	-i      Rebuild text index. 
	-v      Make newest visible for user 'nobody', hide older graphs for dataset. 
    -g      URI  The named graph data is to be loaded in.
    -e      Erase the graph before loading data to it.    
	
## examples:

	./rdfloader -g http://data.bibliotheken.nl/persons/2023-r01/ -f NTA.rdf  
    
Data from NTA.rdf is loaded in the given named graph. 
    
	./rdfloader -d http://data.bibliotheken.nl/id/dataset/persons -f NTA.rdf -v

This will make NTA.rdf visible as dataset, loaded in a new named graph. 
    The URI of the named graph will be based on the existing named graph URI.
    For this, a URI pattern ending in `/{year}-r{two digit sequence}/` is expected.
    The previously used named graph is hidden. As a default, two are kept. Older
    named graphs are deleted. 

	./rdfloader -k 3 -d http://data.bibliotheken.nl/id/dataset/persons -f NTA.rdf -i
	   
As previous, but here 3 older hidden named graphs are kept for this dataset, other graphs for this dataset are deleted. The Virtuoso text index will be rebuild. Visibility (rights for user 'nobody') will not be changed.

Before you start, make sure that `src/settings.sh` has the correct paths for
the `isql` command and the Virtuoso `load_dir`. You can also use a local settings file `src/settings_local.sh` to prevent them from being overwritten. 
    
The relation between an entity `?s` and a dataset `?d` is assumed to be defined by:

	?s <http://schema.org/mainEntityOfPage>/<http://schema.org/isPartOf> ?d .
This may be changed in `src/settings.sh`.

## requirements
Requires the GNU variant of `head`, so when used on MacOS, make sure the GNU coreutils are installed (for example with `brew install coreutils`. 
On Linux, the script will abort when it is not being run from inside a `screen` session.