#! /bin/bash
#
# script to drive the muse command to link a package built
#  in another area to this area so it be used as input to the build
#

usageMuseLink() {
    cat <<EOF

     muse link <repo selection> <options>

     Link making function removed

       <options>
       -h, --help  : print usage
       -r, --rm  : remove existing links

EOF
  return
}

    cat <<EOF

     ********************************************************
       Muse has removed the "link" function, which links
       to individual repos, in favor of the new "backing" function,
       which links to an entre backing build.  This is simpler,
       more convenient, and less likely to lead to inconsistent builds
       You can no longer create links, but you can setup and run 
       old areas containing links.
     ********************************************************

EOF


if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
    usageMuseLink
    exit 0
fi

if [[ "$1" == "-r" || "$1" == "--rm" ]]; then
    rm -rf link
    rm -rf build/*/link
    exit 0
fi


exit 1
