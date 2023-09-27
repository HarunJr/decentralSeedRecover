#!/usr/bin/env bash
set -e
set -o pipefail

source helpers.sh

set -x

getInputTx $1
FROM_UTXO=${SELECTED_UTXO}
FROM_WALLET_NAME=${SELECTED_WALLET_NAME}
FROM_WALLET_ADDRESS=${SELECTED_WALLET_ADDR}
FROM_BALANCE=${SELECTED_UTXO_LOVELACE}

read -p 'Lovelace to send: ' LOVELACE_TO_SEND
read -p 'Token to send: ' TOKEN_TO_SEND
read -p 'Token amount to send: ' TOKEN_AMOUNT
read -p 'Token change: ' TOKEN_CHANGE
read -p 'Receiving wallet name: ' TO_WALLET_NAME

echo TO_WALLET_NAME

if [[ $TO_WALLET_NAME != \addr_* ]];
then 
    TO_WALLET_ADDRESS=$(cat $BASE/.priv/wallets/$TO_WALLET_NAME/$TO_WALLET_NAME.payment.addr)
else
    TO_WALLET_ADDRESS=$TO_WALLET_NAME
fi


build=($CARDANO_CLI transaction build \
--tx-in ${FROM_UTXO} \
--tx-out ${TO_WALLET_ADDRESS}+${LOVELACE_TO_SEND}+"$TOKEN_AMOUNT ${TOKEN_TO_SEND}" \
# --tx-out ${FROM_WALLET_ADDRESS}+${LOVELACE_TO_SEND}+"$TOKEN_CHANGE ${TOKEN_TO_SEND}" \
--change-address=${FROM_WALLET_ADDRESS} \
$PREPROD_TESTNET \
--out-file $WORK/transactions/tx.draft \
--babbage-era)

# print the cardano transaction build
# cat $build
echo $build
# execute the cardano transaction build
"${build[@]}"


$CARDANO_CLI transaction sign \
--tx-body-file $WORK/transactions/tx.draft \
--signing-key-file $BASE/.priv/wallets/${FROM_WALLET_NAME}/${FROM_WALLET_NAME}.payment.skey \
--out-file $WORK/transactions/tx.signed

$CARDANO_CLI transaction submit --tx-file $WORK/transactions/tx.signed $PREPROD_TESTNET
