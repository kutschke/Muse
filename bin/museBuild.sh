#! /bin/bash
#
# script to drive the muse command to build Mu2e analysis repos
#

usageMuseBuild() {
    cat <<EOF

     muse build <options> <scons options>

     Build the code repos ion the Muse working directory.
     This is two steps:
     1) if needed, create links to the build products
        of repos added by "muse link"
     2) run scons in the Muse working dir
     The build directory in the Muse working directory can be deleted to
     effectively remove all build products.  Nothing is written anywhere else.

      <options>
      -h, --help  : print usage

      <scons options>
        All the text here is passed to the scons command line.
        It might include "-j 20" for threaded build, or targets,
        or "-c" to clean the build.

EOF
  return 0
}


if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
    usageMuseBuild
    exit 0
fi

cd $MUSE_WORK_DIR

mkdir -p $MUSE_BUILD_DIR
RC=$?
if [ $RC -ne 0 ]; then
    echo "ERROR - could not execute: mkdir -p $MUSE_BUILD_DIR"
    exit $RC
fi
echo -n "$(date +'%D %H:%M:%S to ')" > $MUSE_BUILD_DIR/.musebuild

#
# make a repo directory in the build area for each repo
# this is used to indicate the repos were built even if it
# produces no files in the build area during the scons build

# first remove old links, which may be stale
rm -f $MUSE_BUILD_DIR/link/*

# this should work for old link style and new backing style
for REPO in $MUSE_LOCAL_REPOS
do
    mkdir -p $MUSE_BUILD_DIR/$REPO
done

#
# now run the local build
#

scons -C $MUSE_WORK_DIR -f $MUSE_DIR/python/SConstruct "$@"
RC=$?

if [ $RC -eq 0 ]; then
    echo  "$(date +'%H:%M:%S')" >> $MUSE_BUILD_DIR/.musebuild
else
    echo  " scons error $RC" >> $MUSE_BUILD_DIR/.musebuild
fi

exit $RC



