#!/bin/bash
#
# This script is for use by those involved in the crossroads 
# acceptance testing effort;
# it is in lieu of a module file or daap install in /usr/projects.
#
# If you need to set LD_LIBRARY_PATH to point to the daap lib for your application,
# do it within the script by uncommenting the corresponding export line below.
# Note that it's generally better to put a hard path in the link line with an -rpath
# type link option.
#
# local variables
# Must be sourced from within the root daap-log directory
prefix="$PWD"
daaplogdir="daap-log"
if [[ "$prefix" != *"$daaplogdir" ]]; then
   echo "This script must be sourced from the root $daaplogdir directory rather than from $prefix."
   echo "Please cd to the location of your daap-log root directory (where this script lives) and source it from there."
   exit 1
fi
bindir="$prefix/bin"
incdir="$prefix/include"
libdir="$prefix/lib"
certsdir="$prefix/daap_certs"
telegrafdir="$prefix/acceptance_configs/telegraf"

if [ -e $prefix ]; then
   echo "daap-log directory path is: $prefix"
else
   echo "$prefix: No such directory."
   echo "Please edit value of \$prefix variable in this script to point to the path of the daap-log directory."
fi

export DAAP_ROOT=$prefix
export DAAP_CERTS=$certsdir
export TELEGRAF_ROOT=$telegrafdir
#export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$libdir"
