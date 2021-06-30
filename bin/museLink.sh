#! /bin/bash
#
# script to drive the muse command to link a package built 
#  in another area to this area so it be used as input to the build
#

usageMuseLink() {
    cat <<EOF

     muse link <repo selection> <options>

     Create a link to a repo in another Muse build area so that package
     can be included in the local build.  The linked package will be included in 
     include, link, fcl and data paths, but it will not itself be built.

      Since this command is usually run before "muse setup", 
      in must be run in the intended muse working directory

      If the command is run without any arguments, or with -l, a list
      of suggested Offline backing builds will be shown

      <repo selection>
           The link selection can be presented various ways
       1) as a path to a repo in a muse working directory:
           muse link /mu2e/app/users/\$USER/myBaseBuild/Offline
       2) a branch/commit for a continuous integration backing build:
           muse link master/c2409d93
       3) the latest master commit from continuous integration
           muse link HEAD
       4) a published Offline tag:
           muse link v09_10_00
               or
           muse link Offline v09_10_00
               or
            muse link Offline (where the current verison will be used)
       5) any other published Musings repo and tag:
           muse link Production MDC2020a
               or
           muse link Production (where the current verison will be used)

       Note: A link is to a repo, not another Muse working directory.
       You cannot link a Musing that is not a single-repo build.  For example,
       if Musings X contains repos Y and Z, then \"muse link X\" will fail. 
       if Musing X contains repo X, then \"muse link X\" will suceed.  
       

       <options>
       -h, --help  : print usage
 
EOF
  return
}


if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
    usageMuseLink
    exit 0
fi

CI_BASE=/cvmfs/mu2e-development.opensciencegrid.org/museCIBuild
MUSINGS=/cvmfs/mu2e.opensciencegrid.org/Musings

TARGET="$1"
VERSION="$2"

#
# if no target, list cvmfs Offline
#

if [[ -z "$TARGET" || "$TARGET" == "-l" ]]; then

    echo "  Recent published Offline releases:"
    CC=$( basename $( readlink -f $MUSINGS/Offline/current ) )
    ls -tr $MUSINGS/Offline | grep -v current | tail -5 | sed "s/$CC/$CC   (current)/"

    echo "  Recent Offline CI builds"
    BRANCHES=$( ls $CI_BASE )
    for BRANCH in $BRANCHES
    do
	find $CI_BASE/$BRANCH -mindepth 1 -maxdepth 1  \
	    -printf "%TY-%Tm-%Td %TH:%TM %p\n" |   \
	    sort -r | sed 's|'$CI_BASE/'||'
    done

    exit 0
fi

#
# try to interpret the target 
#

pubreg="^v[0-9,_]*+$"
FTARGET="no_final_target"
NWORD=$(echo $TARGET | awk -F/ '{print NF}')
PRINTCURRENT="no"

if [[ "$TARGET" == "HEAD" ||  "$TARGET" == "head" ]]; then
    LASTHASH=$(ls -1tr $CI_BASE/master | tail -1)
    FTARGET=$CI_BASE/master/$LASTHASH/Offline
    [ $MUSE_VERBOSE -gt 0 ] && echo "linking CI build Offline master/$LASTHASH"
elif [[ "$TARGET" =~ $pubreg  ]]; then
    # then the first arg was just a verison number, 
    # assume that the intended Musing is Offline
    [ $MUSE_VERBOSE -gt 0 ] && echo "linking published Offline $TARGET"
    # must be a full path
    FTARGET=$MUSINGS/Offline/$TARGET/Offline
elif [ -d $CI_BASE/$TARGET/Offline ]; then
    # the target matched a CI build directory
    FTARGET=$CI_BASE/$TARGET/Offline
    [ $MUSE_VERBOSE -gt 0 ] && echo "linking CI build Offline $TARGET"
elif [[ -d "$TARGET" &&  $NWORD -ne 1 ]]; then
    # the target is a local directory
    # the second clause is necessary because "muse link X"
    # might be issued in an area with a local X dir, 
    # and we would never link that - it is already active
    reg="^/.*"
    if [[ ! "$TARGET"  =~ $reg  ]]; then
	# if target was a relative path, then account for the link subdir
	FTARGET="../$TARGET"
    else
	FTARGET="$TARGET"
    fi
    [ $MUSE_VERBOSE -gt 0 ] && echo "linking local directory $TARGET"
elif [[ -n "$VERSION" &&  -d $MUSINGS/$TARGET/$VERSION/$TARGET ]]; then
    # requested musing and version
    # have to use readlink in case version was "current"
    FTARGET=$( readlink -f $MUSINGS/$TARGET/$VERSION/$TARGET )
    [ $MUSE_VERBOSE -gt 0 ] && echo "linking published Musing $TARGET $VERSION"
    [ "$VERSION" == "current" ] && PRINTCURRENT="yes"
elif [[ -n "$TARGET" &&  -d $MUSINGS/$TARGET/current ]]; then
    # requested current Musing
    FTARGET=$( readlink -f $MUSINGS/$TARGET/current/$TARGET )
    [ $MUSE_VERBOSE -gt 0 ] && echo "linking Musing $TARGET current"
    PRINTCURRENT="yes"
else
    echo "ERROR - target could not be parsed: $TARGET"
    exit 1
fi

if [ "$PRINTCURRENT" == "yes"  ]; then
    TEMPV=$(echo $FTARGET | awk -F/ '{print $(NF-1)}' )
    echo "    $TARGET \"current\" points to $TEMPV"
fi


if [ ! -d link ]; then
    mkdir link
fi

LINK=link/$(basename $FTARGET)
REPO=$( basename $LINK )

if [ -L "$LINK" ]; then
    echo "WARNING - replacing a linked package of the same name: $REPO "
    rm -f $LINK
    # also remove any links to the build area
    # will be recreated pointing to the new area in the next setup
    rm -f build/*/link/$REPO
fi

ln -s $FTARGET $LINK

if [ -n "$MUSE_WORK_DIR" ]; then
    echo "WARNING - Muse is already setup - adding links changes paths.  "
    echo "          You will need start a new process and run \"muse setup\" again. "
fi

exit 0


