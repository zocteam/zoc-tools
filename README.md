# zoc-tools

This is a repository of handy tools related to **01coin**. The main repository for 01coin can be found by [clicking here](https://github.com/zocteam/zeroonecoin).

## 01coin-MasternodeGuide.md

This is a thorough 01coin masternode setup guide detailing all possible methods of installation geared towards all levels of user capability, featuring easy-to-follow images and copy-paste CLI commands.

## README.md
This file that you're reading now.

## mnchecker
This is a customized version for ZOC of this [mnchecker](https://github.com/Aziroshin/mnchecker) originally developed by Christian Knuchel for Vivo. It keeps masternodes synced with the blockchain *as reported by the official explorer*.

## setup_zoc_mn.sh
This tool is a complete setup script for installing a ZOC masternode on a Ubuntu (16.04 or 14.04) VPS, including minimum memory check and add a swapfile if required, software compile or download pre-compiled binaries from git depending on available memory, install mnchecker (above), generate the MN privkey, and install [Sentinel](https://github.com/zocteam/sentinel).

## zeroone.sh
This tool is a user-friendly 01Coin masternode utility menu. It allows easy, menu-based use of the zeroone-cli RPC calls to: start, stop, getinfo, mnsync status, masternode status, masternodelist (wallet) status, and other tools like restart with reindex, restart with latest bootstrap, call sentinel with debug, edit with nano configuration files, edit crontab, etc.

## zoc_max_coin_limit.py
This is a simple python script to help calculate the ZOC max coin supply (note that it includes the disabled premine, so user must factor it manually).

## zoc_mn_queue.sh
This tool shows the current reward selection queue for all network-enabled masternodes. Note that the top 10% of masterodes in this list are slected for reward pseudo-randomly and not sequentially.
