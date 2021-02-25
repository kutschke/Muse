#! /bin/bash
#
# script to drive the muse command to setup and build Mu2e analysis repos
#

[ $MUSE_VERBOSE -gt 0 ] && echo "INFO - running museBuild with args: $@"


scons -C $MUSE_WORK_DIR -f $MUSE_DIR/python/SConstruct "$@"
RC=$?

return $RC



