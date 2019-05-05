#!/usr/bin/env python
#
# Use the raw transactions API to spend zoc received on particular addresses,
# and send any change back to that same address.
#
# Example usage:
#  spendfrom.py  # Lists available funds
#  spendfrom.py --from=ADDRESS --to=ADDRESS --amount=11.00
#
# Assumes it will talk to a zerooned or ZeroOne-Qt running
# on localhost.
#
# Depends on python-bitcoinrpc and ConfigParser
# pip install python-bitcoinrpc
# pip install configparser
# pip install ConfigParser 
#

from decimal import *
import getpass
import math
import os
import os.path
import platform
import sys
import time
import json
import configparser
from itertools import chain

from bitcoinrpc.authproxy import AuthServiceProxy, JSONRPCException
import logging

logging.basicConfig()
#logging.getLogger("BitcoinRPC").setLevel(logging.DEBUG)
logging.getLogger("BitcoinRPC").setLevel(logging.INFO)

BASE_FEE=Decimal("0.001")


def check_json_precision():
    """Make sure json library being used does not lose precision converting ZOC values"""
    n = Decimal("20000000.00000003")
    satoshis = int(json.loads(json.dumps(float(n)))*1.0e8)
    if satoshis != 2000000000000003:
        raise RuntimeError("JSON encode/decode loses precision")


def determine_db_dir():
    """Return the default location of the ZeroOne Core data directory"""
    if platform.system() == "Darwin":
        return os.path.expanduser("~/Library/Application Support/ZeroOneCore/")
    elif platform.system() == "Windows":
        return os.path.join(os.environ['APPDATA'], "ZeroOneCore")
    return os.path.expanduser("~/.zeroonecore")


def read_bitcoin_config(dbdir):
    """Read the zeroone.conf file from dbdir, returns dictionary of settings"""
    #from ConfigParser import SafeConfigParser
    #from configparser import SafeConfigParser
    #class FakeSecHead(object):
    #    def __init__(self, fp):
    #        self.fp = fp
    #        self.sechead = '[all]\n'
    #    def readline(self):
    #        if self.sechead:
    #            try: return self.sechead
    #            finally: self.sechead = None
    #        else:
    #            s = self.fp.readline()
    #            if s.find('#') != -1:
    #                s = s[0:s.find('#')].strip() +"\n"
    #            return s
    #config_parser = SafeConfigParser()
    #config_parser.readfp(FakeSecHead(open(os.path.join(dbdir, "zeroone.conf"), encoding="utf_8"))))
    #config_parser.read_file(FakeSecHead(open(os.path.join(dbdir, "zeroone.conf"))))
    config_parser = configparser.ConfigParser(strict=False)
    #with open(os.path.join(dbdir, "zeroone.conf"), encoding="utf_8") as lines:
    with open(os.path.join(dbdir, "zeroone.conf")) as lines:
      lines = chain(("[all]",), lines)  # This line does the trick.
      config_parser.read_file(lines)
    return dict(config_parser.items("all"))


def connect_JSON(config):
    """Connect to a ZeroOne Core JSON-RPC server"""    
    testnet = config.get('testnet', '0')
    testnet = (int(testnet) > 0)  # 0/1 in config file, convert to True/False
    chain = config.get('chain', 'main')
    if not 'rpcport' in config:
        config['rpcport'] = 10101 if testnet else 10100
    connect = "http://%s:%s@127.0.0.1:%s"%(config['rpcuser'], config['rpcpassword'], config['rpcport'])
    try:
        # result = ServiceProxy(connect)
        result = AuthServiceProxy(connect,timeout=240)
        # ServiceProxy is lazy-connect, so send an RPC command mostly to catch connection errors,
        # but also make sure the zerooned we're talking to is/isn't testnet:
        # if result.getmininginfo()['testnet'] != testnet:
        # if result.getmininginfo()['chain'] != chain :
        if result.getinfo()['testnet'] != testnet:
            sys.stderr.write("RPC server at "+connect+" testnet setting mismatch\n")
            sys.exit(1)
        return result
    except:
        sys.stderr.write("Error connecting to RPC server at "+connect+"\n")
        sys.exit(1)


def unlock_wallet(zerooned):
    info = zerooned.getinfo()
    if 'unlocked_until' not in info:
        return True # wallet is not encrypted
    t = int(info['unlocked_until'])
    if t == 0:
        return True # wallet is fully unlocked
    if t <= time.time():
        try:
            passphrase = getpass.getpass("Wallet is locked; enter passphrase: ")
            zerooned.walletpassphrase(passphrase, 5)
        except:
            sys.stderr.write("Wrong passphrase\n")

    info = zerooned.getinfo()
    return int(info['unlocked_until']) > time.time()


def list_available(zerooned):
    address_summary = dict()

    address_to_account = dict()
    for info in zerooned.listreceivedbyaddress(0):
        address_to_account[info["address"]] = info["account"]

    unspent = zerooned.listunspent(0)
    for output in unspent:
        # listunspent doesn't give addresses, so:
        rawtx = zerooned.getrawtransaction(output['txid'], 1)
        vout = rawtx["vout"][output['vout']]
        pk = vout["scriptPubKey"]

        # This code only deals with ordinary pay-to-zeroone-address
        # or pay-to-script-hash outputs right now; anything exotic is ignored.
        if pk["type"] != "pubkeyhash" and pk["type"] != "scripthash":
            continue

        address = pk["addresses"][0]
        if address in address_summary:
            address_summary[address]["total"] += vout["value"]
            address_summary[address]["outputs"].append(output)
        else:
            address_summary[address] = {
                "total" : vout["value"],
                "outputs" : [output],
                "account" : address_to_account.get(address, "")
                }

    return address_summary


def select_coins(needed, inputs):
    # Feel free to improve this, this is good enough for my simple needs:
    outputs = []
    have = Decimal("0.0")
    n = 0
    while have < needed and n < len(inputs):
        outputs.append({ "txid":inputs[n]["txid"], "vout":inputs[n]["vout"]})
        have += inputs[n]["amount"]
        n += 1
    return (outputs, have-needed)


def create_tx(zerooned, fromaddresses, change_address, toaddress, amount, fee):
    #logging.getLogger("BitcoinRPC").setLevel(logging.DEBUG)
    all_coins = list_available(zerooned)

    total_available = Decimal("0.0")
    needed = amount+fee
    potential_inputs = []
    for addr in fromaddresses:
        if addr not in all_coins:
            continue
        potential_inputs.extend(all_coins[addr]["outputs"])
        total_available += all_coins[addr]["total"]

    if total_available < needed:
        sys.stderr.write("Error, only %f ZOC available, need %f\n"%(total_available, needed));
        sys.exit(1)

    #
    # Note:
    # Python's json/jsonrpc modules have inconsistent support for Decimal numbers.
    # Instead of wrestling with getting json.dumps() (used by jsonrpc) to encode
    # Decimals, I'm casting amounts to float before sending them to zerooned.
    #
    outputs = { toaddress : float(amount) }
    (inputs, change_amount) = select_coins(needed, potential_inputs)
    sys.stderr.write("change_amount: %f ZOC\n"%(change_amount));
    if change_amount > BASE_FEE:  # don't bother with zero or tiny change
        #change_address = fromaddresses[-1]
        if change_address in outputs:
            outputs[change_address] += float(change_amount)
        else:
            outputs[change_address] = float(change_amount)

    #logging.getLogger("BitcoinRPC").setLevel(logging.DEBUG)
    rawtx = zerooned.createrawtransaction(inputs, outputs)
    signed_rawtx = zerooned.signrawtransaction(rawtx)
    if not signed_rawtx["complete"]:
        sys.stderr.write("signrawtransaction failed\n")
        sys.exit(1)
    txdata = signed_rawtx["hex"]
    #logging.getLogger("BitcoinRPC").setLevel(logging.INFO)
    return txdata


def coinswscripts(zerooned,txinfo,hexredeemscript):
    valuein = Decimal("0.0")
    outputs = []

    for vin in txinfo['vin']:
        otxid = vin['txid']
        in_info = zerooned.getrawtransaction(otxid, 1)
        ovoutnum = vin['vout']
        vout = in_info['vout'][ovoutnum]        
        opk = vout['scriptPubKey']
        # This code only deals with ordinary pay-to-zeroone-address
        # or pay-to-script-hash outputs right now; anything exotic is ignored.
        if opk["type"] != "pubkeyhash" and opk["type"] != "scripthash":
            continue		
        #address = pk["addresses"][0]
        ohex = opk["hex"]

        outputs.append({ "txid":otxid, "vout":ovoutnum, "scriptPubKey":ohex, "redeemScript":hexredeemscript })
        valuein = valuein + vout['value']

    return (valuein, outputs)


def create_tx_multisig(zerooned, fromaddresses, change_address, toaddress, amount, fee, msigpkeys, hexredeemscript):
    #logging.getLogger("BitcoinRPC").setLevel(logging.DEBUG)
    all_coins = list_available(zerooned)

    total_available = Decimal("0.0")
    needed = amount+fee
    potential_inputs = []
    for addr in fromaddresses:
        if addr not in all_coins:
            continue
        potential_inputs.extend(all_coins[addr]["outputs"])
        total_available += all_coins[addr]["total"]

    if total_available < needed:
        sys.stderr.write("Error, only %f ZOC available, need %f\n"%(total_available, needed));
        sys.exit(1)

    #
    # Note:
    # Python's json/jsonrpc modules have inconsistent support for Decimal numbers.
    # Instead of wrestling with getting json.dumps() (used by jsonrpc) to encode
    # Decimals, I'm casting amounts to float before sending them to zerooned.
    #
    outputs = { toaddress : float(amount) }
    (inputs, change_amount) = select_coins(needed, potential_inputs)
    sys.stderr.write("change_amount: %f ZOC\n"%(change_amount));
    if change_amount > BASE_FEE:  # don't bother with zero or tiny change
        #change_address = fromaddresses[-1]
        if change_address in outputs:
            outputs[change_address] += float(change_amount)
        else:
            outputs[change_address] = float(change_amount)

    rawtx = zerooned.createrawtransaction(inputs, outputs)
    txinfo = zerooned.decoderawtransaction(rawtx)
    (valuein, voutredeemscripts) = coinswscripts(zerooned,txinfo,hexredeemscript)
    if valuein < needed:
        sys.stderr.write("Error, only %f ZOC in utxos, need %f\n"%(valuein, needed));
        sys.exit(1)
    sys.stderr.write("Ok, about %f ZOC in utxos, need %f\n"%(valuein, needed));
    #logging.getLogger("BitcoinRPC").setLevel(logging.DEBUG)
    signed_rawtx = zerooned.signrawtransaction(rawtx,voutredeemscripts,msigpkeys)
    if not signed_rawtx["complete"]:
        sys.stderr.write("signrawtransaction failed or not completed\n")
        #sys.exit(1)
    txdata = signed_rawtx["hex"]
    #logging.getLogger("BitcoinRPC").setLevel(logging.INFO)
    return txdata


def sign_tx_multisig(zerooned, amount, fee, msigpkeys, hexredeemscript, signrawtxdatain):
    #logging.getLogger("BitcoinRPC").setLevel(logging.DEBUG)
    needed = amount+fee
    txinfo = zerooned.decoderawtransaction(signrawtxdatain)
    (valuein, voutredeemscripts) = coinswscripts(zerooned,txinfo,hexredeemscript)
    if valuein < needed:
        sys.stderr.write("Error, only %f ZOC in utxos, need %f\n"%(valuein, needed));
        sys.exit(1)
    sys.stderr.write("Ok, about %f ZOC in utxos, need %f\n"%(valuein, needed));
    #logging.getLogger("BitcoinRPC").setLevel(logging.DEBUG)
    signed_rawtx = zerooned.signrawtransaction(signrawtxdatain,voutredeemscripts,msigpkeys)
    if not signed_rawtx["complete"]:
        sys.stderr.write("signrawtransaction failed or not completed\n")
        #sys.exit(1)
    txdata = signed_rawtx["hex"]
    #logging.getLogger("BitcoinRPC").setLevel(logging.INFO)
    return txdata


def compute_amount_in(zerooned, txinfo):
    result = Decimal("0.0")
    for vin in txinfo['vin']:
        in_info = zerooned.getrawtransaction(vin['txid'], 1)
        vout = in_info['vout'][vin['vout']]
        result = result + vout['value']
    return result

def compute_amount_out(txinfo):
    result = Decimal("0.0")
    for vout in txinfo['vout']:
        result = result + vout['value']
    return result

def sanity_test_fee(zerooned, txdata_hex, fee, max_fee):
    class FeeError(RuntimeError):
        pass
    try:
        txinfo = zerooned.decoderawtransaction(txdata_hex)
        total_in = compute_amount_in(zerooned, txinfo)
        total_out = compute_amount_out(txinfo)
        if total_in-total_out > max_fee:
            raise FeeError("Rejecting transaction, unreasonable fee of "+str(total_in-total_out))

        tx_size = len(txdata_hex)/2
        kb = tx_size/1000  # integer division rounds down
        if kb > 1 and fee < BASE_FEE:
            raise FeeError("Rejecting no-fee transaction, larger than 1000 bytes")
        if total_in < 0.01 and fee < BASE_FEE:
            raise FeeError("Rejecting no-fee, tiny-amount transaction")
        # Exercise for the reader: compute transaction priority, and
        # warn if this is a very-low-priority transaction

    except FeeError as err:
        sys.stderr.write((str(err)+"\n"))
        sys.exit(1)


def importaddress_from(zerooned, fromaddresses, toaddress, amount, fee):
    #logging.getLogger("BitcoinRPC").setLevel(logging.DEBUG)
    all_coins = list_available(zerooned)

    total_available = Decimal("0.0")
    needed = amount+fee
    potential_inputs = []
    for addr in fromaddresses:
        res = 0
        if addr not in all_coins:
            res = zerooned.importaddress(addr)
        if res < 0:
            sys.stderr.write("importaddress failed %d\n"+str(res))
            sys.exit(1)
        potential_inputs.extend(all_coins[addr]["outputs"])
        total_available += all_coins[addr]["total"]

    if total_available < needed:
        sys.stderr.write("Error, only %f ZOC available, need %f\n"%(total_available, needed));
        sys.exit(1)
    sys.stderr.write("At least %f ZOC available, need %f\n"%(total_available, needed));
    #logging.getLogger("BitcoinRPC").setLevel(logging.INFO)


def main():
    import optparse

    parser = optparse.OptionParser(usage="%prog [options]")
    parser.add_option("--from", dest="fromaddresses", default=None,
                      help="addresses to get zoc from")
    parser.add_option("--to", dest="to", default=None,
                      help="address to get send zoc to")
    parser.add_option("--change", dest="change", default=None,
                      help="address to get the zoc change")
    parser.add_option("--amount", dest="amount", default=None,
                      help="amount to send")
    parser.add_option("--fee", dest="fee", default="0.0",
                      help="fee to include")
    parser.add_option("--datadir", dest="datadir", default=determine_db_dir(),
                      help="location of zeroone.conf file with RPC username/password (default: %default)")
    parser.add_option("--testnet", dest="testnet", default=False, action="store_true",
                      help="Use the test network")
    parser.add_option("--dry_run", dest="dry_run", default=False, action="store_true",
                      help="Don't broadcast the transaction, just create and print the transaction data")
    parser.add_option("--multisig", dest="multisig", default=False, action="store_true",
                      help="Use the multisig handling")
    parser.add_option("--multisigfirststep", dest="multisigfirststep", default=False, action="store_true",
                      help="Use the multisig handling just build and first sign")
    parser.add_option("--multisigsignstep", dest="multisigsignstep", default=False, action="store_true",
                      help="Use the multisig handling just second signs")
    parser.add_option("--multisiglaststep", dest="multisiglaststep", default=False, action="store_true",
                      help="Use the multisig handling just last sign and or broadcast")
    parser.add_option("--hexredeemscript", dest="hexredeemscript", default=None,
    #parser.add_option("--hexredeemscript", dest="hexredeemscript", default="5blabla",
                      help="Use the multisig handling hexredeemscript to sign")
    parser.add_option("--signrawtxdatain", dest="signrawtxdatain", default=None,
    #parser.add_option("--signrawtxdatain", dest="signrawtxdatain", default="0blabla",
                      help="Use the multisig handling signrawtxdatain to sign")
    parser.add_option("--msigpkey", dest="msigpkeys", default=None,
    #parser.add_option("--msigpkey", dest="msigpkeys", default="XxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxXx",
                      help="The multisig pkeys to signrawtransaction")

    (options, args) = parser.parse_args()

    check_json_precision()
    config = read_bitcoin_config(options.datadir)
    if options.testnet: config['testnet'] = True
    #if options.testnet: config['chain'] = 'testnet'
    if options.change is None:
        change_address = options.fromaddresses.split(",")[0]
    else:
        change_address = options.change
    zerooned = connect_JSON(config)

    if options.amount is None:
        address_summary = list_available(zerooned)
        for address,info in address_summary.iteritems():
            n_transactions = len(info['outputs'])
            if n_transactions > 1:
                print("%s %.8f %s (%d transactions)"%(address, info['total'], info['account'], n_transactions))
            else:
                print("%s %.8f %s"%(address, info['total'], info['account']))
    else:
        fee = Decimal(options.fee)
        amount = Decimal(options.amount)
        while unlock_wallet(zerooned) == False:
            pass # Keep asking for passphrase until they get it right
        importaddress_from(zerooned, options.fromaddresses.split(","), options.to, amount, fee)

        if not options.multisig:
            txdata = create_tx(zerooned, options.fromaddresses.split(","), change_address, options.to, amount, fee)
        else:
            if options.multisigfirststep:
                txdata = create_tx_multisig(zerooned, options.fromaddresses.split(","), change_address, options.to, amount, fee, options.msigpkeys.split(","), options.hexredeemscript)
            else:
                if options.multisigsignstep:
                    txdata = sign_tx_multisig(zerooned, amount, fee, options.msigpkeys.split(","), options.hexredeemscript, options.signrawtxdatain)
                else:
                    if options.multisiglaststep:
                        if options.msigpkeys is None:
                            txdata = options.signrawtxdatain
                        else:
                            txdata = sign_tx_multisig(zerooned, amount, fee, options.msigpkeys.split(","), options.hexredeemscript, options.signrawtxdatain)
                    else:
                        sys.stderr.write("Error, multisig step parameter missing...\n");
                        sys.exit(1)
        sanity_test_fee(zerooned, txdata, fee, amount*Decimal("0.01"))
        if options.dry_run or options.multisigfirststep or options.multisigsignstep:
            print("\nresulting raw-tx-hex:\n")
            print(txdata)
        else:
            #logging.getLogger("BitcoinRPC").setLevel(logging.DEBUG)
            txid = zerooned.sendrawtransaction(txdata)
            #logging.getLogger("BitcoinRPC").setLevel(logging.INFO)
            print("\nbroadcasted rawtx with txid:\n")
            print(txid)

if __name__ == '__main__':
    main()
