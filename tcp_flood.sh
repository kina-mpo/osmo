#!/bin/bash

#################################### Variables
LOCKFILE_SRV="/tmp/tcpflood_srv.lock"
LOCKFILE_CLI="/tmp/tcpflood_cli.lock"
NC_MAX=0

#################################### Functions
function helpme {
	echo "$0 <CLIENT|SERVER> <PORT-RANGE> [SRV_IP]"
	echo -e "\n\nEXAMPLES :"
	echo "$0 SERVER 10000-20000"
	echo "$0 CLIENT 10000-20000 192.168.1.1"
	echo ""
	echo "$0 SERVER 10000"
	echo "$0 CLIENT 10000 192.168.1.1"
	exit 1
}

function start_server {
	touch ${LOCKFILE_SRV}
	for PORT in $( seq ${FIRST} ${LAST}) ; do
		netcat -4 -n -l ${PORT} &
	done
	echo "LISTEN        : $(netstat -tlpn | grep 'netcat' | awk '{print $5}' | uniq)"
}

function start_client {
	touch ${LOCKFILE_CLI}
	for PORT in $( seq ${FIRST} ${LAST}) ; do
		netcat -4 -n ${IP_SRV} ${PORT} &
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
if [ "${1}" == "SERVER" ] ; then
	if [ -n "${2}" ] ; then
		MODE="SERVER"
		FIRST="$(echo ${2} | awk -F'-' '{print $1}')"
		LAST="$(echo ${2} | awk -F'-' '{print $2}')"
		if [ -z "${LAST}" ] ; then LAST="${FIRST}" ; fi
		echo "-------------------------------------------"
		echo "MODE          : ${MODE}"
		echo "FIRST_PORT    : ${FIRST}"
		echo "LAST_PORT     : ${LAST}"
		start_server
	else
		helpme
	fi
elif [ "${1}" == "CLIENT" ] ; then
	if [ -n "${2}" ] ; then
		MODE="CLIENT"
		FIRST="$(echo ${2} | awk -F'-' '{print $1}')"
		LAST="$(echo ${2} | awk -F'-' '{print $2}')"
		if [ -z "${LAST}" ] ; then LAST="${FIRST}" ; fi
		echo "-------------------------------------------"
		echo "MODE          : ${MODE}"
		echo "FIRST_PORT    : ${FIRST}"
		echo "LAST_PORT     : ${LAST}"
		if [ -n "${3}" ] ; then
			IP_SRV="${3}"
			start_client
		else
			helpme
		fi
	else
		helpme
	fi
else
	helpme
fi

#################################### Loop update
loading
