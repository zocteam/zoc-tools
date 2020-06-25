#!/bin/sh
echo -e "nr\tstartorpaid\tcurrentime\tpayee-payee-payee-payee-payee-paye\truntimerun\tlastpaidtime\tstarttime"
mn_queue(){
~/zeroone/zeroone-cli masternode list full \
        | grep "[^_]ENABLED 7" \
        | awk -v date="$(date +%s)" '{as=date-$7; mst=(as>$8?as:$8); ru=sprintf("%010d",$7); ze=sprintf("%010d",$8); sep="\t" ; print mst sep date sep $5 sep ru sep ze sep as}' \
        | sort -s -k1,1n \
        | awk '{print NR "\t" $0}'
}
mn_queue
