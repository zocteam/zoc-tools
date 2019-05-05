### SpendFrom ###

Use the raw transactions API to send coins received on a particular
address (or addresses).

### Usage: ###
Depends on json, ConfigParser and [python-bitcoinrpc](https://github.com/jgarzik/python-bitcoinrpc).

	spendfrom.py --from=FROMADDRESS1[,FROMADDRESS2] --to=TOADDRESS --amount=amount \
	             --fee=fee --datadir=/path/to/.zeroonecore --testnet --dry_run

With no arguments, outputs a list of amounts associated with addresses.

With arguments, sends coins received by the `FROMADDRESS` addresses to the `TOADDRESS`.

### Notes ###

- You may explicitly specify how much fee to pay (a fee more than 1% of the amount
will fail,  though, to prevent zoc-losing accidents). Spendfrom may fail if
it thinks the transaction would never be confirmed (if the amount being sent is
too small, or if the transaction is too many bytes for the fee).

- If a change output needs to be created, the change will be sent to the first
`FROMADDRESS` (if you specify just one `FROMADDRESS`, change will go back to it).

- If `--datadir` is not specified, the default datadir is used.

- The `--dry_run` option will just create and sign the transaction and print
the transaction data (as hexadecimal), instead of broadcasting it.

- If the transaction is created and broadcast successfully, a transaction id
is printed.

- If this was a tool for end-users and not programmers, it would have much friendlier
error-handling.

### Enhanced Multisig usage: ###

	spendfrom.py --from=FROMMULTISIGADDRESS --to=TOADDRESS --amount=amount \
	             --fee=fee --datadir=/path/to/.zeroonecore --testnet --dry_run \
	             --multisig --hexredeemscript=MULTISIGREDEEM --msigpkey=MYPKEY2SIGN \
	             --multisigfirststep or --multisigsignstep or --multisiglaststep \
	             --signrawtxdatain="PRE-SIGNED-RAW-TX-HEX-2-SIGN-AND-OR-SEND"

- If the transaction is created and signed a transaction hex dump
is printed.

- If the pre-signed-transaction is newly-signed a transaction hex dump
is printed.

- If the transaction is signed and broadcast successfully, a transaction id
is printed.

- If the transaction is broadcasted successfully, a transaction id
is printed.


### Final note: ###

Before using these scripts 1st backup your local "wallet.dat"... even better you can use a new and empty file "wallet.dat" for using the scripts to spend ZOC from MultiSignature address.
The 1st time before runnig example usage, edit parameters on bat/sh file, then during the 1st run it is normal that will give a timeout error because it will call "importaddress FROMMULTISIG" and it will do a blockchain rescan for that specific address adding all transactions into the wallet.dat in use.


### Donations are welcome:
 
 if these scripts help you out please donate to 01Coin community addresses:
 
    ZOC: 5AchYc7iQS7ynce7hNZ6Ya8djsbm5N9JBS
    BTC: 33aoJAthELcSGsYZJXxV8PAHVYiDECPuJR
    ETH: 0x1189d2c383A6533196b1A63e6FFcA69Edefce9ee (ETH or any ERC-20 Token)
 
