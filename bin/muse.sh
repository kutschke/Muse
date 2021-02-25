#! /bin/bash
#
# script to drive the muse command to setup and build Mu2e analysis repos
#

usage() {

    cat << EOF
 
   System to build multiple Mu2e repos in one scons command 

   muse <global options> action <action options>

   global options:
     -v add verbosity
     - h print help

    action:
      status - print status of setup
      setup  - setup UPS products and path
      build   - run scons

   To see actions options, add "-h" to the action

EOF

}


#
# checks
#
if [ -z "$MU2E" ]; then
    echo "ERROR - muse was not setup"
    return 1
fi


#
# parse arguments
#

# first arg might be verbose flag

export MUSE_VERBOSE=0
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
    export MUSE_VERBOSE=1
    shift
fi

if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    return 0
fi


COMMAND=$1
shift
if [ -z "$COMMAND" ]; then
    echo "ERROR - no muse command word"
    return 1
fi

OWD=$PWD

if [ "$COMMAND" == "setup" ]; then

    #source $MUSE_DIR/bin/museSetup.sh "$@"
    source museSetup.sh "$@"
    RC=$?

elif [ "$COMMAND" == "build" ]; then    

    source $MUSE_DIR/bin/museBuild.sh "$@"
    RC=$?

elif [ "$COMMAND" == "status" ]; then    

    source $MUSE_DIR/bin/museStatus.sh "$@"
    RC=$?

else 
    echo "ERROR - unknown command  $COMMAND"
    return 1
fi

cd $OWD
return $RC


