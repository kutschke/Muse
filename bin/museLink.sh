#! /bin/bash
#
# script to drive the muse command to link a package built 
#  in another area to this area so it be used as input to the build
#

usageLink() {
    cat <<EOF

     muse link <repo selection>

     Create a link to a repo in another Muse build area so that package
     can be included in the local build.  The linked package will be included in 
     include, link, fcl and data paths, but it will not itself be built.

      Since this command is usually run before "muse setup", 
      in must be run in the intended muse working directory

      If the command is run without any arguments, a list
      of suggested Offline backing builds will be shown

      <repo selection>
           The path seelction can be presented three ways
       1) as a path to a repo in a muse working directory:
           muse link /mu2e/app/users/\$USER/myBaseBuild/Offline
       2) a branch/commit for a continuous integration backing build:
           muse link master/c2409d93
       3) a published Offline tag:
           muse link v09_10_00

EOF
  return
}


if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
    usageLink
    exit 0
fi

CI_BASE=/cvmfs/mu2e-development.opensciencegrid.org/museCIBuild
#PUB_BASE=/cvmfs/mu2e.opensciencegrid.org/...

TARGET="$1"

#
# if no target, list cvmfs Offline
#

if [ -z "$TARGET" ]; then

    echo "Recent published releases:"

    echo "Recent CI builds"
    BRANCHES=$( ls $CI_BASE )
    for BRANCH in $BRANCHES
    do
	find $CI_BASE/$BRANCH -mindepth 1 -maxdepth 1  \
	    -printf "%TY-%Tm-%Td %TH:%TM %p\n" |   \
	    sort -r | sed 's|'$CI_BASE/'||'
    done

    # add PUB area when ready

    exit 0
fi


#
# we are assuming that the user specified the target relative 
# to the working dir, if a relative path
#

pubreg="^v[0-9,_]*+$"
FTARGET="no_final_target"

if [[ "$TARGET" =~ $pubreg  ]]; then
    [ $MUSE_VERBOSE -gt 0 ] && echo "would do published Offline $TARGET"
    # must be a full path
    FTARGET=cant_do_pub_$TARGET
elif [ -d $CI_BASE/$TARGET/Offline ]; then
    FTARGET=$CI_BASE/$TARGET/Offline
elif [ -d "$TARGET" ]; then

    reg="^/.*"
    if [[ ! "$TARGET"  =~ $reg  ]]; then
	# if target was a relative path, then account for the link subdir
	FTARGET="../$TARGET"
    else
	FTARGET="$TARGET"
    fi

else
    echo "ERROR - target could not be parsed: $TARGET"
    exit 1
fi

if [ ! -d link ]; then
    mkdir link
fi

LINK=link/$(basename $FTARGET)
REPO=$( basename $LINK )

if [ -e "$LINK" ]; then
    echo "WARNING - replacing a linked package of the same name: $REPO "
    rm -f $LINK
fi

ln -s $FTARGET $LINK

if [ -n "$MUSE_WORK_DIR" ]; then
    echo "WARNING - Muse is already setup - adding links changes paths.  "
    echo "          You will need start a new process and run \"muse setup\" again. "
fi

exit 0


