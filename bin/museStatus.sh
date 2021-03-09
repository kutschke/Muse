#! /bin/bash
#
# script to drive the muse command to setup and build Mu2e analysis repos
#

museStatusUsage() {
    cat <<EOF EOF
 
    muse <global options> status

    <global options>
    -v  : add verbosity
    -h  : print usage

EOF
  return
}


if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
    museStatusUsage
    exit 0
fi


if [ -d build ]; then
    echo ""
    echo "  existing builds:"
    DIRS=$(ls -1 build)
    for DIR in $DIRS; do
	if [ "$DIR" == "$MUSE_STUB" ]; then
	    echo  "     $DIR  ** this is your current setup **"
	else
	    echo  "     $DIR"
	fi
    done
    echo ""
else
    echo ""
    echo "  no existing builds"
    echo ""
fi


[ $MUSE_VERBOSE -gt 0 ] && echo "directory containing repos to be built:"
echo "  MUSE_WORK_DIR = $MUSE_WORK_DIR "
[ $MUSE_VERBOSE -gt 0 ] && echo "space-separated list of local repos to build:"
echo "  MUSE_REPOS = " $MUSE_REPOS
[ $MUSE_VERBOSE -gt 0 ] && echo "the link order of known packages:"
echo "  MUSE_LINK_ORDER = " $MUSE_LINK_ORDER
[ $MUSE_VERBOSE -gt 0 ] && echo "Verbosity, 0 or 1:"
echo "  MUSE_VERBOSE = " $MUSE_VERBOSE
[ $MUSE_VERBOSE -gt 0 ] && echo "user-supplied qualifiers:"
echo "  MUSE_OPTS = " $MUSE_OPTS
[ $MUSE_VERBOSE -gt 0 ] && echo "envset determines the UPS products to use:"
echo "  MUSE_ENVSET = " $MUSE_ENVSET
[ $MUSE_VERBOSE -gt 0 ] && echo "path to find sets of environmental setups:"
echo "  MUSE_ENVSET_DIR  = " $MUSE_ENVSET_DIR
[ $MUSE_VERBOSE -gt 0 ] && echo "build directory stub based on the build options:"
echo "  MUSE_STUB = " $MUSE_STUB
[ $MUSE_VERBOSE -gt 0 ] && echo "the relative path to the build directory:"
echo "  MUSE_BUILD_BASE = " $MUSE_BUILD_BASE
[ $MUSE_VERBOSE -gt 0 ] && echo "full path to build dir:"
echo "  MUSE_BUILD_DIR = " $MUSE_BUILD_DIR
[ $MUSE_VERBOSE -gt 0 ] && echo "location of Muse UPS product"
echo "  MUSE_DIR = " $MUSE_DIR

[ $MUSE_VERBOSE -eq 0 ] && exit 0
echo "build options:"
echo "  MUSE_FLAVOR = " $MUSE_FLAVOR
echo "  MUSE_BUILD = " $MUSE_BUILD
echo "  MUSE_COMPILER_E = " $MUSE_COMPILER_E 
echo "  MUSE_PYTHON = " $MUSE_PYTHON
echo "  MUSE_G4VIS = " $MUSE_G4VIS
echo "  MUSE_G4ST = " $MUSE_G4ST
echo "  MUSE_G4VG = " $MUSE_G4VG
echo "  MUSE_TRIGGER = " $MUSE_TRIGGER
echo "  MUSE_ART = " $MUSE_ART

echo ""
echo "MU2E_BASE_RELEASE=$MU2E_BASE_RELEASE"
echo "MU2E_SEARCH_PATH="
echo $MU2E_SEARCH_PATH | tr ":" "\n"
echo ""
echo "FHICL_FILE_PATH="
echo $FHICL_FILE_PATH | tr ":" "\n"
echo ""
echo "LD_LIBRARY_PATH="
echo $LD_LIBRARY_PATH | tr ":" "\n"
echo ""
echo "PATH="
echo $PATH | tr ":" "\n"
echo ""
echo "ROOT_INCLUDE_PATH="
echo $ROOT_INCLUDE_PATH | tr ":" "\n"

echo ""

exit 0
