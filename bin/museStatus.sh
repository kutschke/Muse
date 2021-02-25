#! /bin/bash
#
# script to drive the muse command to setup and build Mu2e analysis repos
#

usageStatus() {
    cat <<EOF EOF
 
    muse <global options> status

    <global options>
    -v  : add verbosity

EOF
  return
}


[ $MUSE_VERBOSE -gt 0 ] && echo "INFO - running museStatus with args: $@"

if [ "$1" == "-h" ]; then
    usageStatus
    return 0
fi

[ $MUSE_VERBOSE -gt 0 ] && echo "location of Muse UPS product"
echo "  MUSE_DIR = " $MUSE_DIR
[ $MUSE_VERBOSE -gt 0 ] && echo "path to find sets of environmental setups:"
echo "  MUSE_ENVSET_DIR  = " $MUSE_ENVSET_DIR
[ $MUSE_VERBOSE -gt 0 ] && echo "Verbosity, 0 or 1:"
echo "  MUSE_VERBOSE = " $MUSE_VERBOSE
[ $MUSE_VERBOSE -gt 0 ] && echo "directory containing repos to be built:"
echo "  MUSE_WORK_DIR = $MUSE_WORK_DIR "

[ $MUSE_VERBOSE -gt 0 ] && echo "user-supplied qualifiers:"
echo "  MUSE_OPTS = " $MUSE_OPTS
[ $MUSE_VERBOSE -gt 0 ] && echo "build directory stub based on the build options:"
echo "  MUSE_STUB = " $MUSE_STUB
[ $MUSE_VERBOSE -gt 0 ] && echo "the relative path to the build directory:"
echo "  MUSE_BUILD_BASE = " $MUSE_BUILD_BASE
[ $MUSE_VERBOSE -gt 0 ] && echo "full path to build dir:"
echo "  MUSE_BUILD_DIR = " $MUSE_BUILD_DIR
[ $MUSE_VERBOSE -gt 0 ] && echo "space-separated list of local repos to build:"
echo "  MUSE_REPOS = " $MUSE_REPOS
[ $MUSE_VERBOSE -gt 0 ] && echo "envset determines the UPS products to use:"
echo "  MUSE_ENVSET = " $MUSE_ENVSET

[ $MUSE_VERBOSE -gt 0 ] && echo "build options:"
echo "  MUSE_FLAVOR = " $MUSE_FLAVOR
echo "  MUSE_BUILD = " $MUSE_BUILD
echo "  MUSE_COMPILER_E = " $MUSE_COMPILER_E 
echo "  MUSE_PYTHON = " $MUSE_PYTHON
echo "  MUSE_G4VIS = " $MUSE_G4VIS
echo "  MUSE_G4ST = " $MUSE_G4ST
echo "  MUSE_G4VG = " $MUSE_G4VG
echo "  MUSE_TRIGGER = " $MUSE_TRIGGER
echo "  MUSE_ART = " $MUSE_ART

