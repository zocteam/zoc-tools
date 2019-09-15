#!/bin/bash
#echo "usage eg: ./zeroone.sh zeroone 10000 150 "
#echo "call params: 0=bashname($0) 1=basedir($1), 2=port($2), 3=blockTime($3)"
# set defauls zeroone
if [ "$1" == "" ] ;
then
  # name of the coin
  nam="zeroone"
  # daemon port
  dap=10000
  # block period in seconds
  bper=150
  # path to sentinel conf
  sep=~/zoc_sentinel
fi
# set base params of other coin
if [ "$3" != "" ] ;
then
  # name of other coin
  nam=$1
  # daemon port
  dap=$2
  # block period in seconds
  bper=$3
  # path to sentinel
  sep=~/.${nam}core/sentinel
fi
# name limited to 7 chars for menu
menunam=`echo ${nam} | head -c 7`
# name of daemon
dad=`echo ${nam}d`
# name of cli
dac=`echo ${nam}-cli`
# path to cli
mnc=`echo ~/${nam}/${dac}`
# path to daemon
mnd=`echo ~/${nam}/${dad}`
# name of datadir
ndd=`echo .${nam}core`
# path to daemon conf
cfg=`echo ~/${ndd}/${nam}.conf`
# path to mn conf
mfg=`echo ~/${ndd}/masternode.conf`
# path to node debug
mdg=`echo ~/${ndd}/debug.log`
# path to lock
lock=`echo ~/${ndd}/.lock`
# set specific vars to 01vps
if [ "$USER" == "zocuser" ] ;
then
  # 01vps uses zocuser
  sep=~/sentinel
fi
# path to sentinel conf
scf=$sep/sentinel.conf

print_01coin() {
echo "*******************************************************************************"
echo "                 01Coin - The future is in your hands! (c) 2019 "
echo "*******************************************************************************"
echo " The MN menu tool: $0 coinBaseDir externalTcpPort blockTimeSeconds"
echo " usage eg: ./zeroone.sh "
echo " usage eg: ./zeroone.sh zeroone 10000 150 "
echo " usage eg: ./zeroone.sh absolute 18888 150 "
}

print_menu_head() {
echo "*******************************************************************************"
echo "             $menunam Core Masternode Menu (shell script user friend) "
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
    echo " 1) tail -f debug.log   4) nano $menunam.conf           7) Quit"
    echo " 2) clean debug.log     5) nano masternode.conf        8) Back"
    echo " 3) crontab -e          6) nano sentinel.conf          9) OS-infos"
    echo " a) netstat -anp --wide b) ps -ef | grep $dad"
}

menu_debug() {
    print_menu_debug
    while true; do
        read -p "Please enter your choice (any other to show menu):" menu
        case $menu in
            [1]* ) tail -f $mdg;;
            [2]* ) echo 1>$mdg;;
            [3]* ) crontab -e;;
            [4]* ) nano $cfg;;
            [5]* ) nano $mfg;;
            [6]* ) nano $scf;;
            [7]* ) quit;;
            [8]* ) break;;
            [9]* ) os_infos;;
	    [a]* ) netstat -anp --wide | grep $dap;;
	    [b]* ) ps -ef | grep $dad;;
            * ) clear; print_menu_debug; echo "Please select an option.";;
        esac
    done
}

start_mn() {
    cd ~
    echo "$mnd -daemon"
    if [ "$nam" == "zeroone" ] ;
    then
      $mnd -daemon
    else
      $mnd -daemon
    fi
    echo ""
}

stop_mn() {
    cd ~
    echo "$mnc stop"
    ztest=$(pgrep $dad | wc -l)
    zdpid=$(pgrep $dad)
    if [ $ztest -gt 0 ] ;
    then
      #echo "1. zdpid=$zdpid ztest=$ztest"
      $mnc stop
      sleep 10
      while true; do
       zport=$(netstat -an|grep $dap|wc -l)
       #echo "zport=$zport"
       if [ $zport -gt 0 ] ;
       then
          echo " waiting to stop ..."
          sleep 10
       else
          #echo " break p..."
          break
       fi
       zdpid2=$(pgrep $dad)
       #echo "2. zdpid=$zdpid ; zdpid2=$zdpid2 "
       if [ "$zdpid" == "$zdpid2" ] && [ $ztest -eq 1 ] ;
       then
          echo "kill -9 $dad"
          kill -9 $zdpid
          echo "rm -f $lock"
          rm -f $lock
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
    echo "$mnc getinfo"
    $mnc getinfo
    echo ""
}

mnsync_status() {
    cd ~
    echo "$mnc mnsync status"
    $mnc mnsync status
    echo ""
}

masternode_status() {
    cd ~
    echo "$mnc masternode status"
    $mnc masternode status
    echo ""
}

mn_queue(){
    $mnc masternode list full \
        | grep "[^_]ENABLED 7" \
        | awk -v date="$(date +%s)" '{as=date-$7; mst=(as>$8?as:$8); sep="\t" ; print mst sep date sep $5 sep $7 sep $8 sep as}' \
        | sort -s -k1,1n \
        | awk '{print NR "\t" $0}'
}

masternodelist_status() {
    cd ~
    payee=$($mnc masternode status | grep payee | awk -F\" {'print $4'})
    status=$($mnc masternode status | grep status | awk -F\" {'print $4'})
    smnlst=$($mnc masternodelist full ${payee} | grep E | awk -F\  {'print $3'})
    if [ "$payee" == "" ] ;
    then
      echo "status=$status"
    else
      if [ "$nam" == "zeroone" ] ;
      then
        echo "$mnc masternodelist json ${payee}"
        $mnc masternodelist json ${payee}
      else
        echo "$mnc masternodelist full ${payee}"
        $mnc masternodelist full ${payee}
      fi
      echo ""
      echo "The $nam MN reward list state is: $smnlst"
      if [ "$smnlst" == "ENABLED" ] ;
      then
        mnpos=$(mn_queue | grep ${payee} | awk -F\  '{print $1}')
        echo "and will have luck to be a winner in about $mnpos blocks ~ $(($mnpos*$bper/3600)) hours."
      else
        echo "status=$status"
        echo "smnlst=$smnlst"
      fi
    fi
    echo ""
}

restart_reindex() {
    stop_mn
    cd ~
    echo "$mnd -daemon -reindex"
    if [ "$nam" == "zeroone" ] ;
    then
      $mnd -daemon -reindex
    else
      $mnd -daemon -reindex
    fi
    echo ""
}

mnsync_reset() {
    cd ~
    echo "$mnc mnsync reset"
    $mnc mnsync reset
    echo ""
}

restart_bootstrap() {
    cd ~
    cd $ndd
    if [ "$nam" == "zeroone" ] ;
    then
      rm -f bootstrap.dat.old
      wget https://files.01coin.io/mainnet/bootstrap.dat.tar.gz
      tar xvf bootstrap.dat.tar.gz
      rm -f bootstrap.dat.tar.gz
    else
      echo "bootstrap only works if bootstrap.dat.old is present already"
      if [ -f bootstrap.dat.old ] ;
      then
        mv bootstrap.dat.old bootstrap.dat
      fi
    fi
    stop_mn
    cd ~
    cd $ndd
    rm -rf blocks chainstate database fee_estimates.dat mempool.dat netfulfilled.dat db.log governance.dat mncache.dat peers* .lock zerooned.pid banlist.dat debug.log mnpayments.dat
    start_mn
    echo ""
}

sentinel() {
    cd ~
    echo "cd $sep && ./venv/bin/python bin/sentinel.py"
    cd $sep && ./venv/bin/python bin/sentinel.py
    cd ~
    echo ""
}

sentinel_debug() {
    cd ~
    echo "cd $sep && SENTINEL_DEBUG=1 ./venv/bin/python bin/sentinel.py"
    cd $sep && SENTINEL_DEBUG=1 ./venv/bin/python bin/sentinel.py
    cd ~
    echo ""
}

sentinel_force() {
    cd ~
    echo "cd $sep && ./venv/bin/python bin/sentinel.py -b"
    cd $sep && ./venv/bin/python bin/sentinel.py -b
    cd ~
    echo ""
}

info() {
    echo "*******************************************************************************"
    echo "                 01Coin - The future is in your hands! (c) 2019 "
    echo "*******************************************************************************"
    echo " $nam: "
    echo " To manually start the MN : $nam/$dad -daemon "
    echo " To check the node status : $nam/$dac getinfo "
    echo " To check  the  MN status : $nam/$dac masternode status "
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
