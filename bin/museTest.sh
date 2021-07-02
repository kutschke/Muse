# /bin/bash
#
#
#
#
#

usageMuseTest() {
    cat <<EOF
 
    museTest <options> <tests>

     Run the requested Muse tests.

    <options>
    -h, --help  : print usage
    -w, --workdir : builds will be done in workDir/museTest, defaults to 
            /mu2e/data/users/$USER.  Anything found in this dir will be deleted.
    -m, --musedir :  if a local version of Muse is to be tested, this is the path
            
    <tests>
        full - checkout Offline and build prof, checkout Production, 
               make a tarball, and setup and run the tarball
        mgit - link head, checkout Offline, init mgit, setup, build, exit mgit
        link - check various link functions
        setup - check various setup functions

EOF
  return
}

#
# Test functions
#

museTest_full(){
    ! git clone https://github.com/Mu2e/Offline  && return 1
    ! git clone https://github.com/Mu2e/Production  && return 1
    (
	! source muse setup && exit 1
	! muse status && exit 1
	echo "full is building, log file =full/build.log"
	N=$(cat /proc/cpuinfo | grep -c processor)

	muse build -j $N --mu2eCompactPrint >& build.log
	RC=$?
	if [ $RC -ne 0 ]; then
	    echo "[$(date)] build failed with RC=$RC"
	    tail -100 build.log
	    exit 1
	fi

	mu2e -c HelloWorld/test/hello.fcl >& hello.log
	RC=$?
	if [ $RC -ne 0 ]; then
	    echo "[$(date)] hello failed with RC=$RC"
	    tail -50 hello.log
	    exit 1
	fi

	mu2e -n 10 -c Production/Validation/ceSimReco.fcl >& ceSimReco.log
	RC=$?
	if [ $RC -ne 0 ]; then
	    echo "[$(date)] ceSimReco failed with RC=$RC"
	    tail -50 ceSimReco.log
	    exit 1
	fi

	if [ ! -d /mu2e/data/users/$USER ]; then
	    TARSWITCHES=" -e $PWD -t $PWD "
	else
	    TARSWITCHES=""
	fi

	echo "[$(date)] making tar1"
	muse tarball $TARSWITCHES >& tar1.log
	RC=$?
	if [ $RC -ne 0 ]; then
	    echo "[$(date)] tar1 failed with RC=$RC"
	    tail -20 tar1.log
	    exit 1
	fi

	echo "[$(date)] making tar2"
	muse tarball $TARSWITCHES -r Offline/v00 >& tar2.log
	RC=$?
	if [ $RC -ne 0 ]; then
	    echo "[$(date)] tar failed with RC=$RC"
	    tail -20 tar2.log
	    exit 1
	fi

    )
    RC=$?
    if [ $RC -ne 0 ]; then
	echo "[$(date)] muse tarball failed with RC=$RC"	
	return $RC
    fi

    # now test the two tarballs

    # unroll first
    echo "[$(date)] unrolling tar1"
    TBALL=$(cat tar1.log | head -1 | awk '{print $2}' )
    mkdir -p tar1
    tar -C tar1 -xf $TBALL
    RC=$?
    if [ $RC -ne 0 ]; then
	echo "[$(date)] tar failed with RC=$RC"
	return 1
    fi

    # unroll second
    echo "[$(date)] unrolling tar2"
    TBALL=$(cat tar2.log | head -1 | awk '{print $2}' )
    mkdir -p tar2
    tar -C tar2 -xf $TBALL
    RC=$?
    if [ $RC -ne 0 ]; then
	echo "[$(date)] tar failed with RC=$RC"
	return 1
    fi

    # run an exe in each setup
    for TAR in tar1 tar2
    do
	(
	    echo "Running setup in $TAR"
	    if [ "$TAR" == " tar1" ] ; then
		source tar1/Code/setup.sh
		RC=$?
	    else
		source muse setup tar2/Offline/v00
		RC=$?
	    fi
	    if [ $RC -ne 0 ]; then
		echo "[$(date)] setup $TAR failed RC=$RC"
		exit 1
	    fi

	    muse status
	    
	    echo "Running ceSimReco in $TAR"
	    mu2e -n 10 -c Production/Validation/ceSimReco.fcl >& $TAR/ceSimReco.log
	    RC=$?
	    if [ $RC -ne 0 ]; then
		echo "[$(date)] ceSimReco in $TAR failed with RC=$RC"
		tail -50 $TAR/ceSimReco.log
		exit 1
	    fi
	)
	RC=$?
	if [ $RC -ne 0 ]; then
	    echo "[$(date)] $TAR failed in loop with RC=$RC"
	    return 1
	fi
    done

  return 0

}

museTest_mgit(){

    ! git clone https://github.com/Mu2e/Production  && return 1
    
    ! muse link HEAD  && return 1

    ! mgit init  && return 1

    ! cd Offline && return 1
    ! mgit add HelloWorld && return 1
    echo "ls of mgit Offline"
    ls -l
    ! cd .. && return 1

    (
	! source muse setup && exit 1
	! muse status && exit 1
	echo "mgit is building, log file =mgit/build.log"
	N=$(cat /proc/cpuinfo | grep -c processor)

	muse build -j $N --mu2eCompactPrint >& build.log
	RC=$?
	if [ $RC -ne 0 ]; then
	    echo "[$(date)] build failed with RC=$RC"
	    tail -50 build.log
	    exit 1
	fi

	echo "mgit hello test"
	mu2e -c HelloWorld/test/hello.fcl >& hello.log
	RC=$?
	if [ $RC -ne 0 ]; then
	    echo "[$(date)] ERROR - mgit hello failed RC=$RC "
	    tail -50 build.log
	    exit 1
	fi   

	! cd Offline && exit 1
	! mgit quit &&  exit 1
	! cd .. && exit 1
    )

    return 0
}

museTest_setup(){

    LAST=$( ls -1 /cvmfs/mu2e.opensciencegrid.org/Musings/Offline | grep -v current | tail -1)
    LASTCI=$( ls -1tr /cvmfs/mu2e-development.opensciencegrid.org/museCIBuild/master | tail -1)

    for TN in {1..9}
    do
	echo "setup test #$TN"
	(
	    TD="test$TN"
	    if [ $TN -eq 1 ]; then
		source muse setup Offline
	    elif [ $TN -eq 2 ]; then
		source muse setup Offline $LAST
	    elif [ $TN -eq 3 ]; then
		source muse setup $LAST
	    elif [ $TN -eq 4 ]; then
		source muse setup current
	    elif [ $TN -eq 5 ]; then
		source muse setup Offline current
	    elif [ $TN -eq 6 ]; then
		source muse setup HEAD
	    elif [ $TN -eq 7 ]; then
		mkdir $TD
		cd $TD
		muse link HEAD
		git clone https://github.com/Mu2e/Production
		source muse setup
		cd ..
	    elif [ $TN -eq 8 ]; then
		source muse setup master/$LASTCI
	    elif [ $TN -eq 9 ]; then
		source muse setup HEAD -q debug
	    else
		echo "empty test $TN"
	    fi
	    RC=$?
	    if [ $RC -ne 0 ]; then
		echo "[$(date)] setup failed with RC=$RC at test $TN"
		exit 1
	    fi
	    mu2e -c Offline/HelloWorld/test/hello.fcl >& setup_test_${TN}.log
	    RC=$?
	    if [ $RC -ne 0 ]; then
		echo "[$(date)] setup hello failed with RC=$RC at test $TN"
		exit 1
	    fi   
	)
	RC=$?
	[ $RC -ne 0 ] && return $RC
    done

    return 0
}

museTest_link(){
    LAST=$( ls -1 /cvmfs/mu2e.opensciencegrid.org/Musings/Offline | grep -v current | tail -1)
    LASTCI=$( ls -1tr /cvmfs/mu2e-development.opensciencegrid.org/museCIBuild/master | tail -1)

    for TN in {1..3}
    do
	echo "link test #$TN"
	(
	    TD="test$TN"
	    mkdir $TD
	    cd $TD
	    if [ $TN -eq 1 ]; then
		muse link HEAD
	    elif [ $TN -eq 2 ]; then
		muse link master/$LASTCI
	    elif [ $TN -eq 3 ]; then
		muse link /cvmfs/mu2e-development.opensciencegrid.org/museCIBuild/master/$LASTCI/Offline
	    elif [ $TN -eq 4 ]; then
		muse link $LAST
	    elif [ $TN -eq 5 ]; then
		muse link Offline $LAST
	    else
		echo "empty test $TN"
	    fi
	    RC=$?
	    if [ $RC -ne 0 ]; then
		echo "[$(date)] link failed with RC=$RC at test $TN"
		exit 1
	    fi
	    ! source muse setup && exit 1
	    mu2e -c Offline/HelloWorld/test/hello.fcl >& setup_test_${TN}.log
	    RC=$?
	    if [ $RC -ne 0 ]; then
		echo "[$(date)] link hello failed with RC=$RC at test $TN"
		exit 1
	    fi   
	)
	RC=$?
	[ $RC -ne 0 ] && return $RC
    done

    return 0

}

#
# Main
#

echo "[$(date)] Start"


# Parse arguments
PARAMS="$(getopt -o hw:m: -l help,workdir,musedir --name $(basename $0) -- "$@")"
if [ $? -ne 0 ]; then
    echo "ERROR - could not parsing tarball arguments"
    usageMuseTarball
    exit 1
fi
eval set -- "$PARAMS"

WORKBASE=/mu2e/data/users/$USER
MUSEDIR=none
EXTRAS=""
ALLTESTS="full mgit setup link"

while true
do
    case $1 in
        -h|--help)
            usageMuseTest
            exit 0
            ;;
        -w|--workdir)
	    WORKBASE="$2"
            shift 2
            ;;
        -m|--musedir)
	    MUSEDIR="$2"
            shift 2
            ;;
        --)
            shift
	    EXTRAS="$@"
            break
            ;;
        *)
            usageMuseTest
	    break
            ;;
    esac
done

if [ -n "$EXTRAS" ]; then
    TESTS="$EXTRAS"
else
    TESTS="$ALLTESTS"
fi

# enable aliases
shopt -s expand_aliases

if [ "$MUSEDIR" != "none" ]; then
    if [ "$( basename $MUSEDIR )" != "Muse" ]; then
	MUSEDIR=$MUSEDIR/Muse
    fi
    if [ ! -d $MUSEDIR ]; then
	echo "ERROR - musedir $MUSEDIR does not exist "
	exit 1
    fi
    source /cvmfs/mu2e.opensciencegrid.org/setupmu2e-art.sh
    export MUSE_DIR=$MUSEDIR
    export PATH=$MUSEDIR/bin:$PATH
    export MUSE_ENVSET_DIR=$MUSEDIR/config
    alias muse="source muse"
elif [ -z "$MUSE_DIR" ]; then
    source /cvmfs/mu2e.opensciencegrid.org/setupmu2e-art.sh
    setup muse
fi

WORKDIR=$WORKBASE/museTest
echo "MUSE_DIR=$MUSE_DIR"
echo "WORKDIR=$WORKDIR"

if [ ! -f $MUSE_DIR/bin/museSetup.sh ]; then
    echo "ERROR - something wrong in muse setup, no $MUSE_DIR/bin/museSetup.sh"
    exit 1
fi

if ! mkdir -p $WORKDIR; then
    echo "ERROR - failed to mkdir -p $WORKDIR"
    exit 1
fi

for TEST in $TESTS
do
    if ! cd $WORKDIR; then
	echo "ERROR - failed to cd $WORKDIR"
	exit 1	
    fi
    mkdir -p $TEST
    rm -rf $TEST/* $TEST/*.dblite
    if ! cd $TEST; then
	echo "ERROR - failed to cd $TEST"
	exit 1	
    fi
    TESTDIR=$WORKDIR/$TEST
    if ! cd $TESTDIR; then
	echo "ERROR - failed to cd $TESTDIR"
	exit 1
    fi

    echo "[$(date)] Start $TEST"
    museTest_$TEST
    RC=$?
    echo "[$(date)] End $TEST, RC=$RC"
    
done
