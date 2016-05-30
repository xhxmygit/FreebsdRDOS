#!/bin/bash
# Iperf
# Performace test Iperf
# e.g1. Iperf -s
# e.g2. Iperf -c XXX.XXX.XXX.XXX -u
#
# in case of RDOS network stress test iperf param is pass by $IPERF_PARAMS
#

ICA_TESTRUNNING="TestRunning"      # The test is running
ICA_TESTCOMPLETED="TestCompleted"  # The test completed successfully
ICA_TESTABORTED="TestAborted"      # Error during setup of test
ICA_TESTFAILED="TestFailed"        # Error during execution of test

CONSTANTS_FILE="constants.sh"

Usage() {

cat << EOF

This script used to automate RDOS Network stress test

OPTIONS:
	-h Show Help message
	-s Run as Server
	-c Run as Client
	-t Run time of IPerf test
	-p parallel number of process
	-u Run UDP test
e.g.
    1. auto_rdos_Network.sh -s
    2. auto_rdos_Network.sh -c XXX.XXX.XXX.XXX -u
EOF

}

LogMsg()
{
    echo `date "+%a %b %d %T %Y"` : ${1}  # To add the timestamp to the log file
}

UpdateTestState()
{
    echo $1 > ~/state.txt
}


#
# Create the state.txt file so ICA knows we are running
#
LogMsg "Updating test case state to running"
UpdateTestState $ICA_TESTRUNNING

rm -f ~/summary.log
touch ~/summary.log
echo "Covers: Perf tests" >> ~/summary.log
echo "" > ~/iperf.log

#
# Source the constants.sh file to pickup definitions from
# the ICA automation
#
if [ -e ./${CONSTANTS_FILE} ]; then
    source ${CONSTANTS_FILE}
else
    echo "Warn : no ${CONSTANTS_FILE} found"
fi

#
# Make sure the required test parameters are defined
#

if [ "${TARGET_SSHKEY:="UNDEFINED"}" = "UNDEFINED" ]; then
    msg="Error: the TARGET_SSHKEY test parameter is undefined"
    LogMsg "${msg}"
    echo "${msg}" >> ~/summary.log
    UpdateTestState $ICA_TESTFAILED
    exit 20
fi

if [ "${IPERF_PARAMS:="UNDEFINED"}" = "UNDEFINED" ]; then
    msg="Error: the IPERF_PARAMS test parameter is undefined"
    LogMsg "${msg}"
    echo "${msg}" >> ~/summary.log
    UpdateTestState $ICA_TESTFAILED
    exit 30
fi

if [ "${MIMICARP_SERVER_SSHKEY:="UNDEFINED"}" = "UNDEFINED" ]; then
    msg="Error: the MIMICARP_SERVER_SSHKEY test parameter is undefined"
    LogMsg "${msg}"
    echo "${msg}" >> ~/summary.log
    UpdateTestState $ICA_TESTFAILED
    exit 40
fi

#
# initialize variables from input options 
#
LogMsg "INFO Iperf parameter: $IPERF_PARAMS"

SERVER_MAC=
RUN_TIME=10
IS_SERVER=0
IS_UDP=0
IS_DUPLEX_MODE=0
PARA_CNT=2
while getopts "hc:P:t:sud" OPTION $IPERF_PARAMS
do
    case $OPTION in
        h)
            Usage 
            exit 1
            ;;
        c)
            SERVER_MAC=$OPTARG
            ;;
        P)
            PARA_CNT=$OPTARG
            ;;
        t)
            RUN_TIME=$OPTARG
            ;;
        s)
            IS_SERVER=1
            ;;
        u)
            IS_UDP=1
            ;;
        d)
            IS_DUPLEX_MODE=1
            ;;
        ?)
            Usage
            UpdateTestState $ICA_TESTABORTED
            exit 10
            ;;
    esac
done

#
# get ipv4 of server
#

if [[ $IS_SERVER -ne 1 ]] 
then
	if [[ -z $ARP_SERVER || -z $USER ]] 
	then 
		LogMsg "error: not enough information to connect to mimicArpServer"
		UpdateTestState $ICA_TESTFAILED
		exit 50
	fi
	
	timeout=120
	for i in $(seq 1 $timeout)
	do
		LogMsg "$i th try to get ipv4 from mimic arp server"
		LogMsg "ssh -i /root/.ssh/$MIMICARP_SERVER_SSHKEY -o StrictHostKeyChecking no $USER@$ARP_SERVER test -f ~/mimic-arp/$SERVER_MAC"
		ssh -i /root/.ssh/$MIMICARP_SERVER_SSHKEY -o "StrictHostKeyChecking no" $USER@$ARP_SERVER "test -f /root/mimic-arp/$SERVER_MAC"
		if [[ $? -eq 0 ]] 
		then 
			LogMsg "scp -i /root/.ssh/$MIMICARP_SERVER_SSHKEY $USER@$ARP_SERVER:~/mimic-arp/$SERVER_MAC ."
			scp -i /root/.ssh/$MIMICARP_SERVER_SSHKEY -o "StrictHostKeyChecking no" $USER@$ARP_SERVER:~/mimic-arp/$SERVER_MAC .
			break
		else
			sleep 1
		fi
	done
	
	if [[ -f $SERVER_MAC ]] 
	then 
		SERVER_IPV4=`cat $SERVER_MAC`
		LogMsg "success get ipv4: $SERVER_IPV4"
	else 
		echo "ERROR: fail to get ipv4" >> ~/summary.log
		UpdateTestState $ICA_TESTABORTED
		exit 60
	fi
fi

#
# Start iPerf in server mode on the Target machine
# 
# In case of RDOS Network Stress test iperf in server side is launch up in client side 
#
if [[ $IS_UDP -eq 1 ]]
then
	server_command="iperf -s -u"
else
	server_command="iperf -s"
fi
LogMsg "Starting iPerf in server mode on ${SERVER_IPV4}. command: $server_command"

ssh -i /root/.ssh/${TARGET_SSHKEY} -o "StrictHostKeyChecking no" root@${SERVER_IPV4} "echo $server_command | at now"
if [ $? -ne 0 ]; then
    msg="Error: Unable to start iPerf on the Target machine"
    LogMsg "${msg}"
    echo "${msg}" >> ~/summary.log
    UpdateTestState $ICA_TESTFAILED
    exit 70
fi


#
# Give the server a few seconds to initialize
#
LogMsg "Wait 5 seconds so the server can initialize"


sleep 5


#
# create iperf parameters 
#
if [[ $IS_UDP -eq 1 ]]
then 
    if [[ $IS_SERVER -eq 1 ]] 
    then 
		LogMsg "run iperf -s -u"
		param="-s -u"
    else
		LogMsg "iperf -c $SERVER_IPV4 -t $RUN_TIME -P $PARA_CNT -u"
		param="-c $SERVER_IPV4 -t $RUN_TIME -P $PARA_CNT -u"
    fi
else
    if [[ $IS_SERVER -eq 1 ]] 
    then 
		LogMsg "iperf -s"
		param="-s"
    else
		LogMsg "iperf -c $SERVER_IPV4 -t $RUN_TIME -P $PARA_CNT"
		param="-c $SERVER_IPV4 -t $RUN_TIME -P $PARA_CNT"
    fi
fi

LogMsg "IS_DUPLEX_MODE: $IS_DUPLEX_MODE"
if [[ $IS_DUPLEX_MODE -eq 1 ]]
then
	param="$param -d"
	LogMsg "INFO duplex_mode: ture param: $param"
fi

#run iperf here
echo "testing : iperf $param" >> ~/summary.log

rm -f ~/iperf.log
iperf $param >> ~/iperf.log

echo "Iperf test completed successfully" >> ~/summary.log
#
# Let ICA know we completed successfully
#
LogMsg "Updating test case state to completed" 
UpdateTestState $ICA_TESTCOMPLETED

exit 0

