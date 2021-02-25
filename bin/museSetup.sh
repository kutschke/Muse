#! /bin/bash
#
# script to drive the muse command to setup and build Mu2e analysis repos
#

usageSetup() {
  echo setup usage
  return
}



[ $MUSE_VERBOSE -gt 0 ] && echo "INFO - running museSetup with args: $@"


if [ -n "$MUSE_WORK_DIR" ]; then
    echo "ERROR - Muse already setup for directory "
    echo "               $MUSE_WORK_DIR "
    echo "               with OPTS: $MUSE_OPTS"
#TODO - allow repeats for now
#    return 1
fi

if [ -n "$MU2E_BASE_RELEASE" ]; then
    echo "ERROR -  MU2E_BASE_RELEASE already set to $MU2E_BASE_RELEASE"
#TODO - allow repeats for now
#    return 1
fi


#
# determine the working dir, and MUSE_WORK_DIR
#

#echo "DEBUG $1"
if [[ -n "$1" && "$1" != "-q" ]]; then
    if [  ! -d "$1"  ]; then
	echo "ERROR - could not find Muse directory $1"
	return 1
    fi
    # readlink removes links
    export MUSE_WORK_DIR=$(readlink -f $1)
    
    # remove the target dir from args
    shift

else
    export MUSE_WORK_DIR=$(readlink -f $PWD)
fi

[ $MUSE_VERBOSE -gt 0 ] && \
    echo "INFO - set  MUSE_WORK_DIR=$MUSE_WORK_DIR"


#
# set the flavor string
#

if ! which ups >& /dev/null ; then
    echo "ERROR - could not find ups command, please setup mu2e"
    return 1
fi

export MUSE_FLAVOR=$( ups flavor | awk -F- '{print $3}' )

[ $MUSE_VERBOSE -gt 0 ] && echo "INFO - Muse flavor: $MUSE_FLAVOR"

#
# parse arguments - everything should be a qualifier
#

# is -q is there, shift it away
[ "$1" == "-q" ] && shift

# if it is of the form a:b, separate the qualifiers
export MUSE_OPTS=$(echo "$@" | sed 's/:/ /g' )

# defaults
export MUSE_BUILD=""
export MUSE_COMPILER_E=""
export MUSE_PYTHON=""
export MUSE_G4VIS=""
export MUSE_G4ST=""
export MUSE_G4VG=""
export MUSE_TRIGGER=""
export MUSE_ENVSET=""

#
# now parse the words
#

# regex for compiler strings like e19 or e20
rec="^[e][0-9]{2}$"
# regex for version strings like p011 or u000
ree="^[pu][0-9]{3}$"

for WORD in $MUSE_OPTS
do
    echo "parsing $WORD"
    if [ $WORD == "prof" ]; then
	export MUSE_BUILD=prof
    elif [ $WORD == "debug" ]; then
	export MUSE_BUILD=debug
    elif [[ $WORD =~ $rec ]]; then
	export MUSE_COMPILER_E=$WORD
    elif [ $WORD == "ogl" ]; then
	export MUSE_G4VIS=ogl
    elif [ $WORD == "qt" ]; then
	export MUSE_G4VIS=qt
    elif [ $WORD == "st" ]; then
	export MUSE_G4ST=st
    elif [ $WORD == "trigger" ]; then
	export MUSE_TRIGGER=trigger
    elif [ $WORD == "-q" ]; then
	:
    elif [[ $WORD =~ $ree ]]; then
	export MUSE_ENVSET=$WORD
    else
	echo "ERROR - museSetup could not parse $WORD"
	return 1
    fi
done


if [ $MUSE_VERBOSE -gt 0 ]; then
    echo "Parsed qualifiers:"
    echo MUSE_FLAVOR=$MUSE_FLAVOR
    echo MUSE_BUILD=$MUSE_BUILD
    echo MUSE_COMPILER_E=$MUSE_COMPILER_E
    echo MUSE_PYTHON=$MUSE_PYTHON
    echo MUSE_G4VIS=$MUSE_G4VIS
    echo MUSE_G4ST=$MUSE_G4ST
    echo MUSE_G4VG=$MUSE_G4VG
    echo MUSE_TRIGGER=$MUSE_TRIGGER
fi


#
# figure out what environmental setups to run
#
# cases allowed so far
# an explicit qualifier "-q d000"
# Offline is local, pgit or a link, and has a .muse, use .muse content
# $MUSE_WORK_DIR/envset exists, take highest number there
# use highest number from cvmfs
#

if [ -n "$MUSE_ENVSET" ]; then
    # if a set was specified, then do what was requested and done

    if [ $MUSE_VERBOSE -gt 0 ]; then
	echo "INFO - using requested environment $MUSE_ENVSET"
    fi

elif [ -d $MUSE_WORK_DIR/Offline ]; then
    # accepts both local director or link to t a directory

    # if there is a  local Offline, then look for a .muse file

    if [ -f $MUSE_WORK_DIR/Offline/.muse ]; then
	WORD=$( cat $MUSE_WORK_DIR/Offline/.muse | \
	    awk '{if($1=="ENVSET") print $2}' )
	if [ -n "$WORD" ]; then
	    export MUSE_ENVSET=$WORD
	    if [ $MUSE_VERBOSE -gt 0 ]; then 
		echo "INFO - using  environment $MUSE_ENVSET from" 
		echo "           \$MUSE_WORK_DIR/Offline/.muse"
	    fi
	fi
    fi

fi

if [ -z "$MUSE_ENVSET" ]; then

    # take the latest from the env set repo areas
    # if there is a user area, use that first

    if [ -d $MUSE_WORK_DIR/envset ]; then
	WORD=$( find $MUSE_WORK_DIR/envset -maxdepth 1  -type f -printf "%f\n" -regex '^u[0-9]..$' | sort | tail -1 )
	if [ -n "$WORD" ]; then
	    export MUSE_ENVSET=$WORD
	    if [ $MUSE_VERBOSE -gt 0 ]; then 
		echo "INFO - using  environment $MUSE_ENVSET from" 
		echo "           $MUSE_WORK_DIR/envset"
	    fi
	fi
    fi
fi

if [ -z "$MUSE_ENVSET" ]; then
    # if still missing, go to permanent repo of environmental sets
    WORD=$( find $MUSE_ENVSET_DIR -maxdepth 1  -type f -printf "%f\n" -regex '^d[0-9]..$' | sort | tail -1 )
    if [ -n "$WORD" ]; then
	export MUSE_ENVSET=$WORD
	if [ $MUSE_VERBOSE -gt 0 ]; then 
	    echo "INFO - using  environment $MUSE_ENVSET from" 
	    echo "           $MUSE_ENVSET_DIR"
	fi
    fi
fi


if [ $MUSE_VERBOSE -gt 0 ]; then 
    echo "INFO - running $MUSE_ENVSET " 
fi


if [ -r $MUSE_WORK_DIR/envset/$MUSE_ENVSET ]; then
    source $MUSE_WORK_DIR/envset/$MUSE_ENVSET
    RC=$?
elif [ -r $MUSE_ENVSET_DIR/$MUSE_ENVSET ]; then
    source $MUSE_ENVSET_DIR/$MUSE_ENVSET
    RC=$?
else
    echo "ERROR - did not find env set $MUSE_ENVSET"
    RC=1
fi


#
# set the stub for the build path
# this is what allows multiple parallel builds
#

# these are always present
export MUSE_STUB=${MUSE_FLAVOR}-${MUSE_BUILD}-${MUSE_COMPILER_E}-${MUSE_ENVSET}
# TODO leaving this out for now    echo MUSE_PYTHON=$MUSE_PYTHON
[ -n "$MUSE_G4VIS" ]   && export MUSE_STUB=${MUSE_STUB}-$MUSE_G4VIS
[ -n "$MUSE_G4ST" ]    && export MUSE_STUB=${MUSE_STUB}-$MUSE_G4ST
[ -n "$MUSE_G4VG" ]    && export MUSE_STUB=${MUSE_STUB}-$MUSE_G4VG
[ -n "$MUSE_TRIGGER" ] && export MUSE_STUB=${MUSE_STUB}-$MUSE_TRIGGER

export MUSE_BUILD_BASE=build/$MUSE_STUB
export MUSE_BUILD_DIR=$MUSE_WORK_DIR/build/$MUSE_BUILD_BASE

if [ $MUSE_VERBOSE -gt 0 ]; then
    echo MUSE_STUB=$MUSE_STUB
    echo MUSE_BUILD_DIR=$MUSE_BUILD_DIR
fi

#
# now set paths for Offline and the build
#

export MU2E_SEARCH_PATH=$MU2E_DATA_PATH

# list of local packages
# buildable packages have a .muse file in the top directory
export MUSE_REPOS=$(ls -1 */.muse | awk -F/ '{print $1}')

#
# set all the paths for the products in the build dir
#
for PP in $MUSE_REPOS
do

    # undo links to get to real path
    # BASE=$(readlink -f  $MUSE_WORK_DIR/$PP/..)
    BASE=$MUSE_WORK_DIR

    BUILD=$BASE/build/$MUSE_STUB/$PP

    if [ $MUSE_VERBOSE -gt 0 ]; then
	echo "Adding repo $PP to paths"
    fi

# add each package to SimpleConfig path
    export MU2E_SEARCH_PATH=`dropit -p $MU2E_SEARCH_PATH -sf $BASE/$PP`
# add each package source, and any generated fcl 
    export FHICL_FILE_PATH=`dropit -p $FHICL_FILE_PATH -sf $BASE/$PP`
    export FHICL_FILE_PATH=`dropit -p $FHICL_FILE_PATH -sf $BUILD`
# libraries built in each package
    export LD_LIBRARY_PATH=`dropit -p $LD_LIBRARY_PATH -sf $BUILD/lib`
    export CET_PLUGIN_PATH=`dropit -p $CET_PLUGIN_PATH -sf $BUILD/lib`
# bins build in each package
    export PATH=`dropit -p $PATH -sf $BUILD/bin`
    export ROOT_INCLUDE_PATH=`dropit -p $ROOT_INCLUDE_PATH -sf $BASE/$PP`

    if [ -f $PP/.muse ]; then

	PATHS=$(cat $PP/.muse |  \
	    awk '{if($1=="PYTHONPATH") print $2}')
	for PA in $PATHS
	do
	    export PYTHONPATH=`dropit -p $PYTHONPATH -sf $BASE/$PP/$PA`
	done

	PATHS=$(cat $PP/.muse | \
	    awk '{if($1=="PATH") print $2}')
	for PA in $PATHS
	do
	    export PATH=`dropit -p $PATH -sf $BASE/$PP/$PA`
	done

	PATHS=$(cat $PP/.muse | \
	    awk '{if($1=="FHICL_FILE_PATH") print $2}')
	for PA in $PATHS
	do
	    export FHICL_FILE_PATH=`dropit -p $FHICL_FILE_PATH -sf $BASE/$PP/$PA`
	done


    fi
    if [ "$PP" == "Offline" ]; then
	export MU2E_BASE_RELEASE=$BASE/Offline
    fi
done

#
# set paths that start in the MUSE_WORK_DIR
# and can be referred as Offline/JobConfig... or build/.../
#
export MU2E_SEARCH_PATH=`dropit -p $MU2E_SEARCH_PATH -sfe $MUSE_WORK_DIR`
export FHICL_FILE_PATH=`dropit -p $FHICL_FILE_PATH -sfe $MUSE_WORK_DIR`


if [ $MUSE_VERBOSE -gt 0 ]; then
  echo "MU2E_BASE_RELEASE=$MU2E_BASE_RELEASE"
  echo "MU2E_SEARCH_PATH=$MU2E_SEARCH_PATH"
  echo "FHICL_FILE_PATH=$FHICL_FILE_PATH"
  echo "LD_LIBRARY_PATH="$(echo -n $LD_LIBRARY_PATH | tr ":" "\n")
  echo "PATH="$(echo -n $PATH | tr ":" "\n")
  echo "ROOT_INCLUDE_PATH=$ROOT_INCLUDE_PATH"
fi




if [ $RC -ne 0  ]; then
    echo "ERROR - setup did not run correctly"
    return 1
fi


