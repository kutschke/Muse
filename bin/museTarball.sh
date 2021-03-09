#! /bin/bash
#
# script to drive the muse command to setup and build Mu2e analysis repos
#

museTarballUsage() {
    cat <<EOF
 
    muse <global options> tarball <command options> <extras>

    <global options>
    -v, --verbose  : add verbosity

    <command options>
    -h, --help  : print usage
    -t, --tmpdir : temp build space
    -e, --exportdir : landing directory for the tarball
    -a, --all  : tar all builds, default is only the build for the current setup
    -r, --release : release mode, save all code and .git

    <extras>
        extra files or directories to include in the tarball,
        path should be relative to the Muse working directory

EOF
  return
}


# Parse arguments
PARAMS="$(getopt -o ht:e:ar -l tmpdir,exportdir,all,release --name $(basename $0) -- "$@")"
if [ $? -ne 0 ]; then
    echo "ERROR - could not parsing tarball arguments"
    museTarballUsage
    exit 1
fi
eval set -- "$PARAMS"

TMPDIR=/mu2e/data/users/$USER/museTarball
EXPORTDIR=/pnfs/mu2e/resilient/users/$USER/museTarball
ALL=false
RELEASE=false

while true
do
    case $1 in
        -h|--help)
            museTarballUsage
            exit 0
            ;;
        -a|--all)
	    ALL=true
            shift
            ;;
        -t|--tmpdir)
	    TMPDIR="$2"
            shift 2
            ;;
        -e|--exportdir)
	    EXPORTDIR="$2"
            shift
            ;;
        -r|--release)
	    RELEASE=true
            shift
            ;;
        --)
            shift
	    EXTRAS="$@"
            break
            ;;
        *)
            museTarballUsage
	    break
            ;;
    esac
done

# determine and make the directories
mkdir -p $TMPDIR
RC=$?
if [ $RC -ne 0 ]; then
    echo "ERROR could not mkdir $TMPDIR"
    exit 1
fi

TMPSDIR=$( mktemp --directory  --tmpdir=$TMPDIR )
TMPDN=$( basename $TMPSDIR )
EXPORTSDIR=$EXPORTDIR/$TMPDN
TBALL=$TMPSDIR/Code.tar

mkdir -p $EXPORTSDIR
RC=$?
if [ $RC -ne 0 ]; then
    echo "ERROR could not mkdir export dir $EXPORTSDIR"
    exit 1
fi


if [ $MUSE_VERBOSE -gt 0 ]; then
    echo "Temp dir TMPSDIR=$TMPSDIR"
    echo "Export dir EXPORTSDIR=$EXPORTSDIR"
    echo "Include all builds: $ALL"
    echo "Release mode: $RELEASE"
    echo "Extra files: $EXTRAS"
fi


# create an empty tarball
tar -cf $TBALL -T /dev/null
# write to this tarball and do basic excludes like tmp areas
FLAGS=" -rf $TBALL  -X $MUSE_DIR/envset/tarExclude.txt "
if [ "$RELEASE" == "false" ] ; then    # for grid tarball
    # also exclude *.cc and .git
    FLAGS=" $FLAGS  -X $MUSE_DIR/envset/tarExcludeGrid.txt"
    # put it in Code subdirectory
    FLAGS=" $FLAGS  --transform=s|^|Code/| "
fi

# tar any extra files
[ -n "$EXTRAS" ] &&  tar $FLAGS $EXTRAS

# now the builds
linkReg="^link/*"
cvmfsReg="^/cvmfs/*"
for REPO in $MUSE_REPOS
do
    # follow links by default
    FF=" -h "
    DD=$( readlink -f $REPO )  # expanded, true dir
    if [[ "$DD" =~ $cvmfsReg ]]; then
	# if the link is to cvmfs, then just copy in the link
	FF=""
    fi

    [ $MUSE_VERBOSE -gt 0 ] && echo tar $REPO
    tar $FLAGS $FF $REPO

    # now include the repo built parts

    if [ "$ALL" == "true"  ]; then
	# take all existing builds
	BUILDS=$(find build -mindepth 1 -maxdepth 1 -type d)
    else
	# take only the build that's setup
	BUILDS=$MUSE_BUILD_BASE
    fi

    for BUILD in $BUILDS
    do
	[ $MUSE_VERBOSE -gt 0 ] && echo tar $BUILD/$REPO
	for BD in lib bin gen
	do
	    if [ -d $BUILD/$REPO/$BD ]; then
		tar $FLAGS $FF $BUILD/$REPO/$BD
	    fi
	done
    done
done

[ $MUSE_VERBOSE -gt 0 ] && echo "bzip"
bzip2 $TBALL
mv ${TBALL}.bz2 $EXPORTSDIR

echo Tarball: $EXPORTSDIR/Code.tar.bz2

exit 0

