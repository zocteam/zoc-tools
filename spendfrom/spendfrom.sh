#!/bin/bash
MSIGADDR="5AchYc7iQS7ynce7hNZ6Ya8djsbm5N9JBS"
REDEEMSC="5blablaae"
SIGPKEY="XxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXx"
ZOCTO="ZPZHPcmoQpqd3j9ktPf5PetX4SLJkBXFyP"
AMOUNT="1"
FEE="0.005"
ZOCDATADIR="$HOME/.zeroonecore/"

#rem ### PREPARE MULTISIG HEXDATA AND DO FIRST SIGNATURE
#rem --multisigfirststep
#rem --hexredeemscript=
#rem --msigpkey=<my-private-key>
python spendfrom.py --from=$MSIGADDR --change=$MSIGADDR --to=$ZOCTO --amount=$AMOUNT --fee=$FEE --datadir=$ZOCDATADIR --dry_run --multisig --hexredeemscript=$REDEEMSC --msigpkey=$SIGPKEY --multisigfirststep


#rem ### OTHER SIGN A PRE ALREADY SIGNED HEX-RAW-TX-DATA
#rem --multisigsignstep
#rem --signrawtxdatain=<HEX-RAW-TX-DATA-PROVIDED-BY-OTHER-PARTNER>
#RAWSIGTX=020000000...ae2b0180758700000000
#rem python spendfrom.py --from=$MSIGADDR --change=$MSIGADDR --to=$ZOCTO --amount=$AMOUNT --fee=$FEE --datadir=$ZOCDATADIR --dry_run --multisig --hexredeemscript=$REDEEMSC --msigpkey=$SIGPKEY --multisigsignstep --signrawtxdatain=$RAWSIGTX


#rem ### DO LAST THE SIGN REQUIRED ON ALREADY PRE SIGNED HEX-RAW-TX-DATA AND BROADCAST RAW-TX TO THE NETWORK
#rem --multisiglaststep
#rem --signrawtxdatain=<HEX-RAW-TX-DATA-PRE-SIGNED-BY-OTHER-PARTNER>
#rem --msigpkey=<my-private-key>
#PRESIGTXHEX=020000000...ae2b0180758700000000
#rem python spendfrom.py --from=$MSIGADDR --change=$MSIGADDR --to=$ZOCTO --amount=$AMOUNT --fee=$FEE --datadir=$ZOCDATADIR --dry_run --multisig --hexredeemscript=$REDEEMSC --msigpkey=$SIGPKEY --multisiglaststep --signrawtxdatain=$PRESIGTXHEX

#rem ### ALL REQUIRED SIGNATURES SIGNED ONLY BROADCAST RAW-TX TO THE NETWORK
#rem --multisiglaststep
#rem --signrawtxdatain=<ALL-SIGNED-RAW-TX-READY-TO-BROADCAST>
#ALLSIGTXHEX=
#rem python spendfrom.py --from=$MSIGADDR --change=$MSIGADDR --to=$ZOCTO --amount=$AMOUNT --fee=$FEE --datadir=$ZOCDATADIR --dry_run --multisig --hexredeemscript=$REDEEMSC --multisiglaststep --signrawtxdatain=$ALLSIGTXHEX

#rem Error missing multisig step
#rem python spendfrom.py --from=$MSIGADDR --change=$MSIGADDR --to=$ZOCTO --amount=$AMOUNT --fee=$FEE --datadir=$ZOCDATADIR --dry_run --multisig --hexredeemscript=$REDEEMSC --signrawtxdatain=$ALLSIGTXHEX
