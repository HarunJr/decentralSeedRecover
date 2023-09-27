cardano-cli address key-hash --payment-verification-key-file /home/harun/dev/cardano/plutus/cardano-solutions-architect/.priv/wallets/preview/borrower/borrower.vkey

# #!/usr/bin/env bash
# set -e
# set -o pipefail

# if [ -z $1 ]; then
#     echo "createPubKeyHash.sh:  Invalid script arguments. Please provide wallet name or [addr_]"
#     exit 1
# fi

# . "$(dirname $0)"/env # soure env variables

# if [[ $1 != \addr_* ]];
# then 
#     $CARDANO_CLI address key-hash --payment-verification-key-file $(cat $WALLETS/$1/$1.vkey)
#     # WALLET_ADDRESS=$(cat $WALLETS/$1/$1.payment.addr)
# else
#     $CARDANO_CLI address key-hash --payment-verification-key $1
#     # WALLET_ADDRESS=$1
# fi