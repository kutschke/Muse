#! /bin/bash
#
# script to drive the muse command to link a package built 
#  in another area to this area so it be used as input to the build
#

usageLink() {
    cat <<EOF

     muse link path/to/package

     Create a link to a package in another build area so that package
     can be included in the local build.  This package will be included in 
     include and link paths, but it will not itself be built.

     Example:

    > muse link /mu2e/app/users/\$USER/myBaseBuild/Offline
       creates
       linkOffline -> /mu2e/app/users/\$USER/myBaseBuild/Offline

EOF
  return
}


if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
    usageLink
    exit 0
fi

TARGET="$1"

#
# we are assuming that the user specified the target relative 
# to the working dir, if a relative path
#

if [ ! -d "$TARGET" ]; then
        echo "ERROR target is not a directory: $TARGET"
	exit 1
fi

if [ ! -d link ]; then
    mkdir link
fi

reg="^/.*"
if [[ ! "$TARGET"  =~ $reg  ]]; then
    # if target was a relative path, then account for the link subdir
    TARGET="../$TARGET"
fi

LINK=link/$(basename $TARGET)
ln -s $TARGET $LINK

if [ -n "$MUSE_WORK_DIR" ]; then
    echo "WARNING - Muse is already already setup - adding links "
    echo "           requires a new setup in a new process"
fi

exit 0


