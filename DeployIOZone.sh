#!/bin/bash

###########################################################################
#
# DeployIOZone.sh
#
# Description:
# 	For the test to run you have to place the iozone3_420.tar 
#	on '/root' or specify the path of file using -p option 
#
# Parameters:
#     FILE_NAME_IOZONE = /root/iozone3_420.tar
#
############################################################################

LogMsg()
{
    echo `date "+%a %b %d %T %Y"` : ${1}    # To add the time-stamp to the log file
}

Usage() {

cat << EOF

This script used to deploy iozone 

OPTIONS:
	-h Show Help message
	-p specify path of iozone package
e.g.
    1. ./DeployIOZone.sh
    2. ./DeployIOZoneAndIperf.sh -p /root/iozone3_420.tar
EOF

}

FILE_NAME_IOZONE='/root/iozone3_420.tar'
while getopts "hp:" OPTION
do
    case $OPTION in
        h)
            Usage 
            exit 1
            ;;
        p)
            FILE_NAME_IOZONE=$OPTARG
            ;;
        ?)
            Usage
            exit 10
            ;;
    esac
done

LogMsg "package of IOZone : $FILE_NAME_IOZONE"

#
# Install iozone and check if the installation is successful
#
IOZONE=${FILE_NAME_IOZONE}

if [ ! -e ${IOZONE} ];
then
    LogMsg "Cannot find iozone file." 
    exit 20
fi

# Get Root Directory of the archive
ROOTDIR=`tar -tvf ${IOZONE} | head -n 1 | awk -F " " '{print $6}' | awk -F "/" '{print $1}'`

tar -xvf ${IOZONE}
sts=$?
if [ 0 -ne ${sts} ]; then
    LogMsg "Failed to extract the iozone archive!"
    exit 30
fi
 
if [ !  ${ROOTDIR} ];
then
    LogMsg "Cannot find ROOTDIR." 
    exit 40
fi

cd ${ROOTDIR}/src/current

#
# Compile iozone
#
make linux
sts=$?
if [ 0 -ne ${sts} ]; then
	echo "make linux : Failed" 
	exit 50
else
	echo "make linux: Success"

fi

#
# Add iozone to PATH
#
echo export PATH='$PATH':`pwd` >> /root/.bashrc

LogMsg "iozone was installed successfully!"

exit 0