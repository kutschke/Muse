#
# Define some helper functions which provide text such as build options
# and library lists to be used in SConstruct.  Also there are a few functions
# that perform little tasks - put here to keep SConstruct more readable.
#

from glob import glob
import os, re, string

import sys
import subprocess

# Check that some of the required environment variables have been set
# and derive and check other pieces of the environment
# return a dictionary with mu2eOpts
def mu2eEnvironment():
    mu2eOpts = {}

    # the directory that includes local repos and 'build'
    workDir = os.environ['MUSE_WORK_DIR']

    # subdir where built files are put
    buildBase = 'build/'+os.environ['MUSE_STUB']

    mu2eOpts['workDir'] = workDir
    mu2eOpts['buildBase'] = buildBase
    mu2eOpts['libdir'] = buildBase+'/lib'
    mu2eOpts['bindir'] = buildBase+'/bin'
    mu2eOpts['gendir'] = buildBase+'/gen'

# create a list of repos in link order
    repos = os.environ['MUSE_REPOS'].split()
    order = os.environ['MUSE_LINK_ORDER'].split()
    ordered = ""
    for r in order:
        if r in repos :  # add it to the end, in order
            ordered = ordered + " " + r
        else :  # if unknown, add it to the front
            ordered = r + " " + ordered
    
    mu2eOpts['repos'] = ordered

    # prof or debug
    mu2eOpts['build'] = os.environ['MUSE_BUILD']
    if len(os.environ['MUSE_G4VIS'])>0:
        mu2eOpts['g4vis'] = os.environ['MUSE_G4VIS']
    else:
        mu2eOpts['g4vis'] = 'none'

    if len(os.environ['MUSE_G4ST'])>0:
        mu2eOpts['g4mt'] = 'off'
    else:
        mu2eOpts['g4mt'] = 'on'

    if len(os.environ['MUSE_G4VG'])>0:
        mu2eOpts['g4vg'] = 'on'
    else:
        mu2eOpts['g4vg'] = 'off'

    if len(os.environ['MUSE_TRIGGER'])>0:
        mu2eOpts['trigger'] = 'on'
    else:
        mu2eOpts['trigger'] = 'off'

    return mu2eOpts

# the list of root libraries
# This comes from: root-config --cflags --glibs
def rootLibs():
    return [ 'GenVector', 'Core', 'RIO', 'Net', 'Hist', 'MLP', 'Graf', 'Graf3d', 'Gpad', 'Tree',
             'Rint', 'Postscript', 'Matrix', 'Physics', 'MathCore', 'Thread', 'Gui', 'm', 'dl' ]


# the include path
def cppPath(mu2eOpts):

    path = []
    # add the build directory of each package, for generated code
    for repo in mu2eOpts['repos'].split():
        path.append(mu2eOpts["workDir"]+'/'+repo)
    # the directory containing the local repos
    path.append(mu2eOpts["workDir"])

    path = path + [
        os.environ['ART_INC'],
        os.environ['ART_ROOT_IO_INC'],
        os.environ['CANVAS_INC'],
        os.environ['BTRK_INC'],
        os.environ['MESSAGEFACILITY_INC'],
        os.environ['FHICLCPP_INC'],
        os.environ['HEP_CONCURRENCY_INC'],
        os.environ['SQLITE_INC'],
        os.environ['CETLIB_INC'],
        os.environ['CETLIB_EXCEPT_INC'],
        os.environ['BOOST_INC'],
        os.environ['CLHEP_INC'],
        os.environ['CPPUNIT_DIR']+'/include',
        os.environ['HEPPDT_INC'],
        os.environ['ROOT_INC'],
        os.environ['XERCES_C_INC'],
        os.environ['TBB_INC'],
        os.environ['MU2E_ARTDAQ_CORE_INC'],
        os.environ['ARTDAQ_CORE_INC'],
        os.environ['PCIE_LINUX_KERNEL_MODULE_INC'],
        os.environ['TRACE_INC'],
        os.environ['GSL_INC'],
        os.environ['POSTGRESQL_INC']
        ]

    return path

# the ld_link_library path
def libPath(mu2eOpts):

    path = []

    # the built lib area of each local repo
    # the order was determined above
    for repo in mu2eOpts['repos'].split():
        path.append('#/'+mu2eOpts["buildBase"]+'/'+repo+'/lib')

    path = path + [
        os.environ['ART_LIB'],
        os.environ['ART_ROOT_IO_LIB'],
        os.environ['CANVAS_LIB'],
        os.environ['BTRK_LIB'],
        os.environ['MU2E_ARTDAQ_CORE_LIB'],
        os.environ['ARTDAQ_CORE_LIB'],
        os.environ['PCIE_LINUX_KERNEL_MODULE_LIB'],
        os.environ['MESSAGEFACILITY_LIB'],
        os.environ['HEP_CONCURRENCY_LIB'],
        os.environ['FHICLCPP_LIB'],
        os.environ['SQLITE_LIB'],
        os.environ['CETLIB_LIB'],
        os.environ['CETLIB_EXCEPT_LIB'],
        os.environ['BOOST_LIB'],
        os.environ['CLHEP_LIB_DIR'],
        os.environ['CPPUNIT_DIR']+'/lib',
        os.environ['HEPPDT_LIB'],
        os.environ['ROOTSYS']+'/lib',
        os.environ['XERCESCROOT']+'/lib',
        os.environ['TBB_LIB'],
        os.environ['GSL_LIB'],
        os.environ['POSTGRESQL_LIBRARIES']
        ]

    return path

# Define the compiler and linker options.
# These are given to scons using its Evironment.MergeFlags call.
def mergeFlags(mu2eOpts):
    build = mu2eOpts['build']
    flags = ['-std=c++17','-Wall','-Wno-unused-local-typedefs','-g',
             '-Werror','-Wl,--no-undefined','-gdwarf-2', '-Wl,--as-needed',
             '-Werror=return-type','-Winit-self','-Woverloaded-virtual', '-DBOOST_BIND_GLOBAL_PLACEHOLDERS' ]
    if build == 'prof':
        flags = flags + [ '-O3', '-fno-omit-frame-pointer', '-DNDEBUG' ]
    elif build == 'debug':
        flags = flags + [ '-O0' ]
    return flags


# Prepare some shell environmentals in a form to be pushed
# into the scons environment.
def exportedOSEnvironment():
    osenv = {}
    for var in [ 'LD_LIBRARY_PATH',  'GCC_FQ_DIR',  'PATH', 'PYTHONPATH',
                 'ROOTSYS', 'PYTHON_ROOT', 'PYTHON_DIR', 'SQLITE_FQ_DIR', 
                 'MUSE_WORK_DIR', 'MUSE_BUILD_BASE']:
        if var in os.environ.keys():
            osenv[var] = os.environ[var]
    return osenv

# list of BaBar libs
def BaBarLibs():
    return [ 'BTrk_KalmanTrack', 'BTrk_DetectorModel', 'BTrk_TrkBase',
             'BTrk_BField','BTrk_BbrGeom', 'BTrk_difAlgebra',
             'BTrk_ProbTools','BTrk_BaBar', 'BTrk_MatEnv' ]

# Walk the directory tree to locate all SConscript files.
# this runs in the scons top source dir, which is MUSE_WORK_DIR
def sconscriptList(mu2eOpts):
    ss = []
    for repo in mu2eOpts['repos'].split():
        if not os.path.islink(repo):
            for root, dirs, files in os.walk(repo, followlinks = False):
                if 'SConscript' in files:
                    ss.append(os.path.join(root, 'SConscript'))

    return ss



# with -c, scons will remove all dependant files it knows about
# but when a source file is deleted:
# - the .os file will be left in the build dir
# - the dict and lib now contain extra objects
# so explicitly delete all files left in the build dir
def extraCleanup():
    for top, dirs, files in os.walk(mu2eOpts['buildBase']):
        for name in files:
            ff =  os.path.join(top, name)
            print("removing file ", ff)
            os.unlink (ff)
