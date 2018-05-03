#!/bin/bash
echo "*******************************************************************************"
echo "               Zero One Coin Masternode Setup Shell Scipt"
echo "                               Created by Evydder"
echo "*******************************************************************************"

configQuestions()
{
	echo "*******************************************************************************"
	echo "                                    Config"
	echo "*******************************************************************************"

	#IP
	vpsip=$(dig +short myip.opendns.com @resolver1.opendns.com)
	while true; do
		read -p "Is Your VPS IP: ${vpsip} ? [Y/N]" yn
		case $yn in
			[Yy]* ) break;;
			[Nn]* ) echo "Please Type In Your VPS IP"; read vpsip;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	rpcuser=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32})
	rpcpassword=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32})
	
	#Needed to be appended to the file before ask for incase of want to gen key Privatekey
	if [ ! -d ".zeroonecore" ]; then
		mkdir .zeroonecore 
	fi
	
	echo "rpcuser=${rpcuser}" >> .zeroonecore/zeroone.conf
	echo "rpcpassword=${rpcpassword}" >> .zeroonecore/zeroone.conf
	
	while true; do
		read -p "Would You Like To Provide An Private key  : ${privkey} ? [Y/N]" yn
		case $yn in
			[Yy]* ) askforprivatekey;break;;
			[Nn]* ) genkey;break;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	echo "**************************************************************"
	while true; do
		read -p "Would You Like An Shell Scipt To Start The Node?[Y/N]" yn
		case $yn in
			[Yy]* ) echo "zeroone/zerooned -daemon ">> startZeroOne.sh;askstartonboot;break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done
	
	echo "**************************************************************"
	while true; do
		read -p "Would You Like To Install An Node Manager To Keep The Block Chain Synced?[Y/N]" yn
		case $yn in
			[Yy]* ) setup_manager;break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done
}

install_preqs()
{
	echo "*******************************************************************************"
	echo "                           Installing Prequirements"
	echo "*******************************************************************************"

	sudo apt install -y software-properties-common
	sudo add-apt-repository -y ppa:bitcoin/bitcoin
	sudo apt update 
	sudo apt upgrade -y 
	sudo apt install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libboost-all-dev libdb4.8-dev libdb4.8++-dev python-virtualenv nano git openssl
}

download()
{
	echo "*******************************************************************************"
	echo "                     Downloading Installing ZeroOneCoin"
	echo "*******************************************************************************"
	
	if [ "$release" = '14.04' ] 
	then
		wget https://github.com/zocteam/zeroonecoin/releases/download/V0.12.1.6/zeroone-linux.tar.gz
		tar -xvf zeroone-linux.tar.gz
		rm zeroone-linux.tar.gz
	fi
	if [ "$release" = '16.04' ] 
	then
	#Only needed for 16.04
		sudo apt-get install -y libminiupnpc-dev 
		wget https://github.com/zocteam/zeroonecoin/releases/download/V0.12.1.6/zeroone-linux.tar.gz
		tar -xvf zeroone-linux.tar.gz
		rm zeroone-linux.tar.gz
	fi
	
	mkdir .zeroonecore
}

config()
{
	echo "*******************************************************************************"
	echo "                      Configing ZeroOneCoin Masternode"
	echo "*******************************************************************************" 
	
	echo "externalip=${vpsip}:10000" >> .zeroonecore/zeroone.conf
	echo "masternode=1" >> .zeroonecore/zeroone.conf
	echo "masternodeprivkey=${privkey}" >> .zeroonecore/zeroone.conf
	echo "maxconnections=25" >> .zeroonecore/zeroone.conf
}

start_mn()
{
	echo "*******************************************************************************"
	echo "                       Starting ZeroOneCoin Masternode"
	echo "*******************************************************************************"

	zeroone/zerooned -daemon

	echo 'If The Above Says "ZeroOne Core server starting" Then Masternode is Installed' 
	echo "On Your Wallet Please Append the Following In The Masternode.conf"
	echo "MN-X ${vpsip}:10000 ${privkey} collateral_output_txid collateral_output_index"
}

adds_nodes()
{
	killall zerooned
	#fixes error if folders dont exist
	if [ ! -d ".zeroonecore" ]; then
		mkdir .zeroonecore 
	fi	
	addnodes
	#Reason for not starting it manuly is i don't know where its installed
	echo "*******************************************************************************"
	echo "                    Please Manualy Start Your Masternode"
	echo "*******************************************************************************"

	info
	#Kill off the program
	exit 1
}

compile()
{
#checks ram and makes swap if nessary
	ram="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
	minram="1048576"
	if [ "$ram" -le "$minram" ]
	then
		dd if=/dev/zero of=/swapfile count=2048 bs=1M
		chmod 600 /swapfile
		mkswap /swapfile
		swapon /swapfile
		echo "/swapfile   none    swap    sw    0   0" > /etc/fstab
	fi
	# Download and Compile 
	git clone https://github.com/zocteam/zeroonecoin
	cd zeroonecoin
	sudo ./autogen.sh
	sudo ./configure CXXFLAGS="--param ggc-min-expand=1 --param ggc-min-heapsize=32768"
	cpucores = grep -c ^processor /proc/cpuinfo
	sudo make -j$cpucores
	mkdir ~/zeroone
	mv ~/zeroonecoin/src/zerooned ~/zeroone/zerooned
	mv ~/zeroonecoin/src/zeroone-cli ~/zeroone/zeroone-cli
	mv ~/zeroonecoin/src/zeroone-tx ~/zeroone/zeroone-tx
}

askforprivatekey(){
#Masternode Priv Key
	read privkey
	while true; do
		read -p "Is This The Correct Private Key : ${privkey} ? [Y/N]" yn
		case $yn in
			[Yy]* ) break;;
			[Nn]* ) echo "Please Type In The Correct Private Key"; read privkey;;
			* ) echo "Please answer yes or no.";;
		esac
	done
}

askstartonboot(){
echo "**************************************************************"
	while true; do
		read -p "Would You Like To Start The Node On Boot?[Y/N]" yn
		case $yn in
			[Yy]* ) startonboot;break;;
			[Nn]* ) break;;
			* ) echo "Please answer yes or no.";;
		esac
	done
}

startonboot(){
	chmod -x startZeroOne.sh
	chmod 777 startZeroOne.sh
	sudo echo "@reboot /root/startZeroOne.sh" >> /etc/crontab
}

genkey()
{
		zeroone/zerooned -daemon
		echo "Waiting for ZeroOne To Start So Can Genkey"
		sleep 10
		privkey=$(zeroone/zeroone-cli masternode genkey)
		killall zerooned
}
info()
{

	echo "*******************************************************************************"
	echo "To Manual Start The Node Run              : zeroone/zerooned -daemon "
	echo "To Check The Status Of The Masternode Run : zeroone/zeroone-cli getinfo "
	echo ""
	echo "If You Require Any Help Ask On The Discord Server : https://discord.gg/jbMjjnV"
	echo ""
	echo "If This Helps You Out And You Want To Tip :"
	echo "(ZOC) ZNZL6JXTeF3nP8fSWf46wbRqAMjLezyRHK"
	echo "*******************************************************************************"

}

install_mn(){
#Checks Versions
release=$(lsb_release -r -s)
case $release in
"14.04")
	download;;

"16.04")
	download;;

*)
	compile;;
	esac
}
setup_manager()
{
	killall zerooned
	wget https://raw.githubusercontent.com/zocteam/zoc-tools/master/mnchecker
	chmod 777 mnchecker
	echo "rpcport=10101" >> .zeroonecore/zeroone.conf
	sudo echo "*/10 * * * * /root/mnchecker --currency-bin-cli=/root/zeroone/zeroone-cli --currency-bin-daemon=/root/zeroone/zerooned --currency-datadir=.zeroonecore" >> /etc/crontab

}
#checks args then runs the functions
case $1 in
compile)
	configQuestions
	install_preqs
	compile
	config
	start_mn
	info;;
manager)
	setup_manager;;
*)
	install_mn
	configQuestions
	install_preqs
	config
	start_mn
	info
;;
esac
