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
