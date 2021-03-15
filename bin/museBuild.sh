#! /bin/bash
#
# script to drive the muse command to build Mu2e analysis repos
#

cd $MUSE_WORK_DIR

#
# "build" the linked packages by making sure the links 
# from our build area to the backing build area are there
#
if [ -d link ]; then
    # we should be in $MUSE_WORK_DIR
    mkdir -p $MUSE_BUILD_BASE/link
    for REPO in $( ls  link )
    do
	BASE=$( readlink -f  link/$REPO/.. )
	if [ ! -d  $MUSE_BUILD_BASE/link/$REPO  ]; then
	    if [ -d  $BASE/$MUSE_BUILD_BASE/$REPO ]; then
		ln -s $BASE/$MUSE_BUILD_BASE/$REPO $MUSE_BUILD_BASE/link/$REPO  
	    fi
	fi
    done
fi

#
# now run the local build
#

scons -C $MUSE_WORK_DIR -f $MUSE_DIR/python/SConstruct "$@"
RC=$?

exit $RC



