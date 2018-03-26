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
	vpsip="$(dig +short myip.opendns.com @resolver1.opendns.com)" 
	while true; do
		read -p "Is Your VPS IP: ${vpsip} ? [Y/N]" yn
		case $yn in
			[Yy]* ) break;;
			[Nn]* ) echo "Please Type In Your VPS IP"; read vpsip;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	#RPC Username
	echo "Please Enter Your rpcuser"
	read rpcuser
	while true; do
		read -p "Is This The Correct rpcuser : ${rpcuser} ? [Y/N]" yn
		case $yn in
			[Yy]* ) break;;
			[Nn]* ) echo "Please Type In The Correct rpcuser"; read rpcuser;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	#RPC Pasword
	echo "Please Enter Your rpcpassword"
	read rpcpassword
	while true; do
		read -p "Is This The Correct rpcpassword : ${rpcpassword} ? [Y/N]" yn
		case $yn in
			[Yy]* ) break;;
			[Nn]* ) echo "Please Type In The Correct rpcpassword"; read rpcpassword;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	#Masternode Priv Key
	echo "Please Enter Your privkey"
	read privkey
	while true; do
		read -p "Is This The Correct privkey : ${privkey} ? [Y/N]" yn
		case $yn in
			[Yy]* ) break;;
			[Nn]* ) echo "Please Type In The Correct privkey"; read privkey;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	echo "**************************************************************"
	while true; do
		read -p "Would You Like An Shell Scipt To Start The Node?[Y/N]" yn
		case $yn in
			[Yy]* ) echo "zeroone/zerooned -daemon ">> startZeroOne.sh;break;;
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
	sudo apt install -y build-essential libtool autotools-devautomake pkg-config libssl-dev libevent-dev bsdmainutils libboost-all-dev libdb4.8-dev libdb4.8++-dev python-virtualenv nano git
	sudo apt install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libboost-all-dev libdb4.8-dev libdb4.8++-dev python-virtualenv nano git
}

download()
{
	echo "*******************************************************************************"
	echo "                     Downloading Installing ZeroOneCoin"
	echo "*******************************************************************************"

	mkdir zeroone
	cd zeroone
	wget https://github.com/zeroonecoin/zeroonecoin/raw/master/release/zeroone-linux.tar.gz
	tar -xvf zeroone-linux.tar.gz
	rm zeroone-linux.tar.gz
	cd ..
	mkdir .zeroonecore
}

config()
{
	echo "*******************************************************************************"
	echo "                      Configing ZeroOneCoin Masternode"
	echo "*******************************************************************************"

	echo "rpcuser=${rpcuser}" >> .zeroonecore/zeroone.conf
	echo "rpcpassword=${rpcpassword}" >> .zeroonecore/zeroone.conf
	echo "externalip=${vpsip}:10000" >> .zeroonecore/zeroone.conf
	echo "masternode=1" >> .zeroonecore/zeroone.conf
	echo "masternodeprivkey=${privkey}" >> .zeroonecore/zeroone.conf
	echo "maxconnections=25" >> .zeroonecore/zeroone.conf
}

addnodes()
{
	echo "addnode=103.69.195.185:58848" >> .zeroonecore/zeroone.conf
	echo "addnode=13.56.174.183:10000" >> .zeroonecore/zeroone.conf
	echo "addnode=13.59.197.120:10000" >> .zeroonecore/zeroone.conf
	echo "addnode=144.202.17.171:10000" >> .zeroonecore/zeroone.conf
	echo "addnode=174.138.10.244:10000" >> .zeroonecore/zeroone.conf
	echo "addnode=185.224.249.58:45325" >> .zeroonecore/zeroone.conf
	echo "addnode=213.183.51.7:10000" >> .zeroonecore/zeroone.conf
	echo "addnode=45.32.6.178:34558" >> .zeroonecore/zeroone.conf
	echo "addnode=62.77.153.115:10000" >> .zeroonecore/zeroone.conf
	echo "addnode=79.165.207.31:57377" >> .zeroonecore/zeroone.conf
	echo "addnode=90.145.172.88:10000" >> .zeroonecore/zeroone.conf
	echo "addnode=90.156.157.28:10000" >> .zeroonecore/zeroone.conf
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

#checks args then runs the functions
case $1 in
nodes)
	adds_nodes;;

Nodes)
	adds_nodes;;

addnodes)
	adds_nodes;;
*)
	configQuestions
	install_preqs
	download
	config
	addnodes
	start_mn
	info
;;
esac
