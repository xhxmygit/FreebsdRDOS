#!/bin/bash

###########################################################################
#
# DeployIperf.sh
#
# Description: 
#	For the test to run you have to place the iperf-2.0.5.tar.gz
#	on '/root' or specify the path of file using -p option
#
# Parameters:
#     FILE_NAME_IPERF = /root/iperf-2.0.5.tar.gz
#
############################################################################

LogMsg()
{
    echo `date "+%a %b %d %T %Y"` : ${1}    # To add the time-stamp to the log file
}

Usage() {

cat << EOF

This script used to deploy iperf

OPTIONS:
	-h Show Help message
	-p specify path of iperf package
e.g.
    1. ./DeployIperf.sh
    2. ./DeployIperf.sh -p /root/iperf-2.0.5.tar.gz
EOF

}

FILE_NAME_IPERF='/root/iperf-2.0.5.tar.gz'
while getopts "hp:" OPTION
do
    case $OPTION in
        h)
            Usage 
            exit 1
            ;;
        p)
            FILE_NAME_IPERF=$OPTARG
            ;;
        ?)
            Usage
            exit 10
            ;;
    esac
done

LogMsg "package of IPerf : $FILE_NAME_IPERF"

#
# Install iperf and check if the installation is successful
#

#
# Extract the files from the IPerf tar package
#
tar -xzf ${FILE_NAME_IPERF}
if [ $? -ne 0 ]; then
    LogMsg "Error: Unable extract ${FILE_NAME_IPERF}"
    exit 20
fi

#
# Get the root directory of the tarball
#
rootDir=`tar -tzf ${FILE_NAME_IPERF} | sed -e 's@/.*@@' | uniq`
if [ -z ${rootDir} ]; then
    LogMsg "Error: Unable to determine root directory if ${FILE_NAME_IPERF} tarball"
    exit 30
fi

LogMsg "rootDir = ${rootDir}"
cd ${rootDir}

#
# Build iperf
#
./configure
if [ $? -ne 0 ]; then
    LogMsg "Error: ./configure failed"
    exit 40
fi

make
if [ $? -ne 0 ]; then
    LogMsg "Error: Unable to build iperf"
    exit 50
fi

make install
if [ $? -ne 0 ]; then
    LogMsg "Error: Unable to install iperf"
    exit 60
fi

LogMsg "iperf was installed successfully!"

exit 0