#!/bin/bash

RSLT_FILE="/tmp/floodping_childs_nbp"

function flood {
        LINE="$(ping -w ${TEMPS} -f ${IP} | grep 'transmitted')"
        NB_PCK_T="$(echo ${LINE} | awk '{print $1}')"
        NB_PCK_R="$(echo ${LINE} | awk '{print $4}')"
        echo "${NB_PCK_T},${NB_PCK_R}" >> ${RSLT_FILE}
}

function loading {
        while true ; do
                echo -ne "\r|"
                sleep 0.25
                echo -ne "\r/"
                sleep 0.25
                echo -ne "\r-"
                sleep 0.25
                echo -ne "\r\\"
                sleep 0.25
        done
}
export -f loading


if [ -z "${3}" ] ; then
        echo "$0 <IP_ADDR> <TEMPS> <NB_CHILD>"
        exit 1
fi

IP="${1}"
TEMPS="${2}"
NB_CHILDS="${3}"
echo "-------------------------------------------"
echo "IP              : ${IP}"
echo "TEMPS           : ${TEMPS}s"
echo "NB_CHILDS       : ${NB_CHILDS}"
for NB in $(seq 1 ${NB_CHILDS}) ; do
        flood &
done
timeout $((TEMPS+1)) bash -c loading
TOTAL=0
for NBPT in $(cat ${RSLT_FILE} | awk -F',' '{print $1}') ; do
        TOTALT=$((TOTAL+NBPT))
done
for NBPR in $(cat ${RSLT_FILE} | awk -F',' '{print $2}') ; do
        TOTALR=$((TOTAL+NBPR))
done
echo -e "\rNB_PQTS_ENVOYES : ${TOTALT}p"
echo -e "NB_PQTS_RECUS   : $((TOTALR))p"
echo -e "NB_PQTS_PERDUS  : $((TOTALT-TOTALR))p"
echo -e "%_PERTES        : $(( 100 - (TOTALR * 100 / TOTALT) ))%"
echo -e "PQTS_PAR_SEC    : $((TOTALT/TEMPS))p/s"

rm ${RSLT_FILE}
