#!/bin/bash
############################################################################
#
# Linux on Hyper-V and Azure Test Code, ver. 1.0.0
# Copyright (c) Microsoft Corporation
#
# All rights reserved. 
# Licensed under the Apache License, Version 2.0 (the ""License"");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0  
#
# THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS
# OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
# ANY IMPLIED WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR
# PURPOSE, MERCHANTABLITY OR NON-INFRINGEMENT.
#
# See the Apache Version 2.0 License for specific language governing
# permissions and limitations under the License.
#
############################################################################

ICA_TESTRUNNING="TestRunning"      # The test is running
ICA_TESTCOMPLETED="TestCompleted"  # The test completed successfully
ICA_TESTABORTED="TestAborted"      # Error during setup of test
ICA_TESTFAILED="TestFailed"        # Error during running of test

CONSTANTS_FILE="constants.sh"

LogMsg()
{
    echo `date "+%a %b %d %T %Y"` : ${1}    # To add the timestamp to the log file
}

UpdateTestState()
{
    echo $1 > ~/state.txt
}

SetValue()
{
    OLD_VALUE=$(cat $1)
    LogMsg "$1 's old value is $OLD_VALUE"
    if [ "$OLD_VALUE" -ne "$2" ]; then
        LogMsg "Changing $1 to $2"
        echo $2 > $1
    fi
}

#
# Create the state.txt file so ICA knows we are running
#
LogMsg "Updating test case state to running"
UpdateTestState $ICA_TESTRUNNING

#
# Source the constants.sh file to pickup definitions from
# the ICA automation
#
if [ -e ./$CONSTANTS_FILE ]; then
    LogMsg "CONSTANTS FILE: $(cat $CONSTANTS_FILE)"
    source $CONSTANTS_FILE
else
    echo "Warn : no ${CONSTANTS_FILE} found"
fi

if [ -e ~/summary.log ]; then
    LogMsg "Cleaning up previous copies of summary.log"
    rm -f ~/summary.log
fi

DATA_DISK=sdb
if ! fdisk -l | grep "Disk /dev/$DATA_DISK"; then
    LogMsg "The /dev/$DATA_DISK not found"
    echo "The /dev/$DATA_DISK not found" >> ~/summary.log
    LogMsg "aborting the test."
    UpdateTestState $ICA_TESTABORTED
    exit 30
fi

SetValue /sys/module/scsi_mod/parameters/scsi_logging_level 63
SetValue /sys/block/$DATA_DISK/device/timeout 180

echo "Test data disk : /dev/$DATA_DISK" >> ~/summary.log

# Format and mount disk
(echo n; echo p; echo 1; echo; echo; echo w) | fdisk /dev/$DATA_DISK
DATA_PARTITION=/dev/${DATA_DISK}1
mkfs.ext3 $DATA_PARTITION
if [ $? -ne 0 ]; then
    LogMsg "Error in creating file system.."
    echo "Creating file system : Failed" >> ~/summary.log
    UpdateTestState $ICA_TESTFAILED
    exit 80
fi
LogMsg "mkfs.ext3 $DATA_PARTITION successful..."

#find /sys/devices -name 'provisioning_mode' -exec sh -c 'echo -n unmap > $1' -- {} \;

mkdir /mnt/data
#mount -o discard $DATA_PARTITION /mnt/data
mount $DATA_PARTITION /mnt/data
if [ $? -eq 0 ]; then
    LogMsg "Drive mounted successfully..."    
else
    LogMsg "Error in mounting drive..."
    echo "Drive mount : Failed" >> ~/summary.log
    UpdateTestState $ICA_TESTFAILED
    exit 70
fi
#mount -o remount,discard /

# 
# Run iozone for throughput test
#
LogMsg "Running iozone $IOZONE_PARAMS on /mnt/data"
cd /mnt/data;
iozone $IOZONE_PARAMS > /root/IOZoneLog.log

if [[ $? -eq 0 ]]; then
	LogMsg "IOzone test completed successfully"
	echo "IOzone test completed successfully" >> ~/summary.log
else
	LogMsg "Failed to run IOzone. test Failed"
	echo "Running IOZone : Failed" >> ~/summary.log
	UpdateTestState $ICA_TESTFAILED
    exit 90
fi

#
# Let ICA know we completed successfully
#
LogMsg "Updating test case state to completed"
UpdateTestState $ICA_TESTCOMPLETED

exit 0