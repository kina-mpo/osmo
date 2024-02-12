#!/bin/bash

#################################### Variables
LOCKFILE_SRV="/tmp/tcpflood_srv.lock"
LOCKFILE_CLI="/tmp/tcpflood_cli.lock"
LOGFILE_SRV="/tmp/tcpflood_srv.log"
LOGFILE_CLI="/tmp/tcpflood_cli.log"
NC_MAX=0

#################################### Functions
function helpme {
	echo "/!\\ LAUNCH AS ROOT /!\\"
	echo "$0 <CLIENT|SERVER> <PORT> [NB_CHILDS] [SRV_IP]"
	echo -e "\n\nEXAMPLE :"
	echo "$0 SERVER 10000"
	echo "$0 CLIENT 10000 100 192.168.1.1"
	exit 1
}

function start_server {
	touch ${LOCKFILE_SRV}
	netcat -4 -n -l ${1} &
}

function start_client {
	touch ${LOCKFILE_CLI}
	for CHILD in $( seq 1 ${1}) ; do
		netcat -4 -n ${2} ${3} &
	done
}

function stop_all {
	echo -e "\r-------------------------------------------"
	echo -e "MAX_ESTABLISH : ${NC_MAX}"
    	echo -e "-------------------------------------------"
	killall netcat
	rm -f ${LOCKFILE_SRV}
	rm -f ${LOCKFILE_CLI} 
}

function loading {
        while true ; do
		NC_EST="$(netstat -tapn | grep 'netcat' | grep 'ESTABLISHED' | wc -l)"
		if [ ${NC_EST} -gt ${NC_MAX} ] ; then
			NC_MAX=${NC_EST}
		fi
                echo -ne "\rESTABLISHED | : ${NC_EST}       "
                sleep 0.1 || break
                echo -ne "\rESTABLISHED / : ${NC_EST}       "
                sleep 0.1 || break
                echo -ne "\rESTABLISHED - : ${NC_EST}       "
                sleep 0.1 || break
                echo -ne "\rESTABLISHED \\ : ${NC_EST}       "
                sleep 0.1 || break
        done
}

#################################### Initialisation
export -f loading
trap stop_all INT
if [ "${USER}" != "root" ] ; then helpme ; fi
if [ "${1}" == "SERVER" ] ; then
	if [ -n "${2}" ] ; then
		MODE="SERVER"
		echo "-------------------------------------------"
		echo "MODE          : SERVER"
		echo "LISTEN        : 0.0.0.0:${2}"
		start_server ${2}
	else
		helpme
	fi
elif [ "${1}" == "CLIENT" ] ; then
	if [ -n "${2}" ] && [ -n ${3} ] && [ -n ${4} ] ; then
		echo "-------------------------------------------"
		echo "MODE          : CLIENT"
		echo "SERVER        : ${4}:${2}"
		echo "NB_CHILDS     : ${3}"
		start_client ${3} ${4} ${2}
	else
		helpme
	fi
else
	helpme
fi

#################################### Loop update
loading
