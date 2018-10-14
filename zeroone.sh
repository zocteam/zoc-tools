#!/bin/bash

print_01coin() {
echo "*******************************************************************************"
echo "                 01Coin - The future is in your hands! (c) 2018 "
echo "*******************************************************************************"
}

print_menu_head() {
echo "*******************************************************************************"
echo "             ZeroOne Core Masternode Menu (shell script user friend)"
echo "*******************************************************************************"
}

print_menu_basic() {
    print_menu_head
   #echo "*******************************************************************************"
    echo " 1) start               4) mnsync status               7) Quit"
    echo " 2) stop                5) masternode status           8) Advanced"
    echo " 3) getinfo             6) masternodelist status       9) Debug"
}

menu_basic() {
	print_menu_basic
    while true; do
        read -p "Please enter your choice (any other to show menu):" menu
        case $menu in
            [1]* ) start_mn;;
            [2]* ) stop_mn;;
            [3]* ) getinfo;;
            [4]* ) mnsync_status;;
            [5]* ) masternode_status;;
            [6]* ) masternodelist_status;;
            [7]* ) quit;;
            [8]* ) break;;
            [9]* ) menu_debug; clear; print_menu_basic;;
            * ) clear; print_menu_basic; echo "Please select an option.";;
        esac
    done
}

print_menu_advanced() {
    print_menu_head
   #echo "*******************************************************************************"
    echo " 1) restart reindex     4) sentinel                    7) Quit"
    echo " 2) mnsync reset        5) sentinel debug              8) Basic"
    echo " 3) restart bootstrap   6) sentinel force              9) Debug"
}

menu_advanced() {
    print_menu_advanced
    while true; do
        read -p "Please enter your choice (any other to show menu):" menu
        case $menu in
            [1]* ) restart_reindex;;
            [2]* ) mnsync_reset;;
            [3]* ) restart_bootstrap;;
            [4]* ) sentinel;;
            [5]* ) sentinel_debug;;
            [6]* ) sentinel_force;;
            [7]* ) quit;;
            [8]* ) break;;
            [9]* ) menu_debug; clear; print_menu_advanced;;
            * ) clear; print_menu_advanced; echo "Please select an option.";;
        esac
    done
}

print_menu_debug() {
    print_menu_head
   #echo "*******************************************************************************"
    echo " 1) tail -f debug.log   4) nano zeroone.conf           7) Quit"
    echo " 2) clean debug.log     5) nano masternode.conf        8) Back"
    echo " 3) crontab -e          6) nano sentinel.conf          9) OS-infos"
}

menu_debug() {
    print_menu_debug
    while true; do
        read -p "Please enter your choice (any other to show menu):" menu
        case $menu in
            [1]* ) tail -f ~/.zeroonecore/debug.log;;
            [2]* ) echo 1>~/.zeroonecore/debug.log;;
            [3]* ) crontab -e;;
            [4]* ) nano ~/.zeroonecore/zeroone.conf;;
            [5]* ) nano ~/.zeroonecore/masternode.conf;;
            [6]* ) nano ~/zoc_sentinel/sentinel.conf;;
            [7]* ) quit;;
            [8]* ) break;;
            [9]* ) os_infos;;
            * ) clear; print_menu_debug; echo "Please select an option.";;
        esac
    done
}

start_mn() {
    cd ~
    echo "zeroone/zerooned -daemon"
    zeroone/zerooned -daemon -assumevalid=0000000005812118515c654ab36f46ef2b7b3732a6115271505724ff972417c7
    echo ""
}

stop_mn() {
    cd ~
    echo "zeroone/zeroone-cli stop"
    ztest=$(pgrep zerooned | wc -l)
    zdpid=$(pgrep zerooned)
    if [ $ztest -gt 0 ] ;
    then
      #echo "1. zdpid=$zdpid ztest=$ztest"
      zeroone/zeroone-cli stop
      sleep 10
      while true; do
       zport=$(netstat -an|grep 10000|wc -l)
       #echo "zport=$zport"
       if [ $zport -gt 0 ] ;
       then
          echo " waiting to stop ..."
          sleep 10
       else
          #echo " break p..."
          break
       fi
       zdpid2=$(pgrep zerooned)
       #echo "2. zdpid=$zdpid ; zdpid2=$zdpid2 "
       if [ "$zdpid" == "$zdpid2" ] && [ $ztest -eq 1 ] ;
       then
          #echo "kill -9 $zdpid"
          kill -9 $zdpid
          rm -f ~/.zeroonecore/.lock
       else
          #echo " break k..."
          break
       fi
      done
    else
      echo " already stopped ..."
    fi
    echo ""
}

getinfo() {
    cd ~
    echo "zeroone/zeroone-cli getinfo"
    zeroone/zeroone-cli getinfo
    echo ""
}

mnsync_status() {
    cd ~
    echo "zeroone/zeroone-cli mnsync status"
    zeroone/zeroone-cli mnsync status
    echo ""
}

masternode_status() {
    cd ~
    echo "zeroone/zeroone-cli masternode status"
    zeroone/zeroone-cli masternode status
    echo ""
}

mn_queue(){
    zeroone/zeroone-cli masternode list full \
        | grep "[^_]ENABLED 7" \
        | awk -v date="$(date +%s)" '{as=date-$7; mst=(as>$8?as:$8); sep="\t" ; print mst sep date sep $5 sep $7 sep $8 sep as}' \
        | sort -s -k1,1n \
        | awk '{print NR "\t" $0}'
}

masternodelist_status() {
    cd ~
    payee=$(zeroone/zeroone-cli masternode status | grep payee | awk -F\" {'print $4'})
    status=$(zeroone/zeroone-cli masternode status | grep status | awk -F\" {'print $4'})
    if [ "$payee" == "" ] ;
    then
      echo "status=$status"
    else
      echo "zeroone/zeroone-cli masternodelist json ${payee}"
      zeroone/zeroone-cli masternodelist json ${payee}
      #zeroone/zeroone-cli masternodelist json ${vpsip}
      echo ""
      mnpos=$(mn_queue | grep ${payee} | awk -F\  '{print $1}')
      echo "will have luck to be a winner in about $mnpos blocks ~ $(($mnpos*150/3600)) hours."
    fi
    echo ""
}

restart_reindex() {
    stop_mn
    cd ~
    echo "zeroone/zerooned -daemon -reindex"
    zeroone/zerooned -daemon -reindex -assumevalid=0000000005812118515c654ab36f46ef2b7b3732a6115271505724ff972417c7
    echo ""
}

mnsync_reset() {
    cd ~
    echo "zeroone/zeroone-cli mnsync reset"
    zeroone/zeroone-cli mnsync reset
    echo ""
}

restart_bootstrap() {
    cd ~
    cd .zeroonecore
    rm -f bootstrap.dat.old
    wget https://files.01coin.io/mainnet/bootstrap.dat.tar.gz
    tar xvf bootstrap.dat.tar.gz
    rm -f bootstrap.dat.tar.gz
    stop_mn
    cd ~
    cd .zeroonecore
    rm -rf blocks chainstate database fee_estimates.dat mempool.dat netfulfilled.dat db.log governance.dat mncache.dat peers.dat .lock zerooned.pid banlist.dat debug.log mnpayments.dat
    start_mn
    echo ""
}

sentinel() {
    cd ~
    echo "cd zoc_sentinel && ./venv/bin/python bin/sentinel.py"
    cd zoc_sentinel && ./venv/bin/python bin/sentinel.py
    cd ~
    echo ""
}

sentinel_debug() {
    cd ~
    echo "cd zoc_sentinel && SENTINEL_DEBUG=1 ./venv/bin/python bin/sentinel.py"
    cd zoc_sentinel && SENTINEL_DEBUG=1 ./venv/bin/python bin/sentinel.py
    cd ~
    echo ""
}

sentinel_force() {
    cd ~
    echo "cd zoc_sentinel && ./venv/bin/python bin/sentinel.py -b"
    cd zoc_sentinel && ./venv/bin/python bin/sentinel.py -b
    cd ~
    echo ""
}

info() {
    echo "*******************************************************************************"
    echo "                 01Coin - The future is in your hands! (c) 2018 "
    echo "*******************************************************************************"
    echo ""
    echo " To manually start the MN : zeroone/zerooned -daemon  "
    echo " To check the node status : zeroone/zeroone-cli getinfo "
    echo " To check  the  MN status : zeroone/zeroone-cli masternode status "
    echo ""
    echo " If you need help please ask in the Discord server: https://discord.gg/sFYnBpu "
    echo ""
    echo " If this helps you out you can donate to 01Coin community addresses:"
    echo "  ZOC: 5AchYc7iQS7ynce7hNZ6Ya8djsbm5N9JBS "
    echo "  BTC: 33aoJAthELcSGsYZJXxV8PAHVYiDECPuJR "
    echo "  ETH: 0x1189d2c383A6533196b1A63e6FFcA69Edefce9ee (ETH or any ERC-20 Token)"
    echo ""
    echo "                           Thank You And Have A Nice Day "
    echo "*******************************************************************************"
}

quit() {
    info
    exit 0
}

os_infos() {
    echo "*******************************************************************************"
    echo "                          OS usefull informations "
    echo "*******************************************************************************"
    release=$(lsb_release -r -s)
    echo "release = $release"
    echo "user = $USER"
    echo "home = $HOME"
    ram=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    echo "ram = $ram"
    cpucores=$(grep -c ^processor /proc/cpuinfo)
    echo "cpucores = $cpucores"
    vpsip=$(dig +short myip.opendns.com @resolver1.opendns.com)
    echo "vpsip = $vpsip"
	echo cat /etc/issue
    cat /etc/issue
	echo df -h
	df -h
	echo free -h
	free -h
    echo uname -a
	uname -a
    echo "*******************************************************************************"
}

print_01coin
while true; do
    menu_basic
    menu_advanced 
done
