#!/usr/bin/env bash

set -e
set -o pipefail

source helpers.sh

# set -x

read -p 'Script name to spend from: ' SCRIPT_NAME

SCRIPT_FILE=$WORK/plutus-scripts/${SCRIPT_NAME}.plutus 
SCRIPT_ADDRESS=$($CARDANO_CLI address build --payment-script-file $SCRIPT_FILE --testnet-magic $TESTNET_MAGIC)
mkdir -p $BASE/.priv/wallets/${SCRIPT_NAME}
echo $SCRIPT_ADDRESS > $BASE/.priv/wallets/${SCRIPT_NAME}/${SCRIPT_NAME}.payment.addr

# cat $SCRIPT_ADDRESS

POLICY_ID=$($CARDANO_CLI transaction policyid --script-file $SCRIPT_FILE)

# cat $POLICY_ID

section "Select Collateral UTxO"
read -p 'Collateral wallet name: ' COLLATERAL
getInputTx ${COLLATERAL}
COLLATERAL_TX=$SELECTED_UTXO
FEE_ADDR=$SELECTED_WALLET_ADDR

read -p 'Lovelace to send: ' LOVELACE_TO_SEND
read -p 'Receiving wallet name: ' TO_WALLET_NAME

if [[ $TO_WALLET_NAME != \addr_* ]];
then 
    TO_WALLET_ADDRESS=$(cat $BASE/.priv/wallets/$TO_WALLET_NAME/$TO_WALLET_NAME.payment.addr)
else
    TO_WALLET_ADDRESS=$TO_WALLET_NAME
fi

POLICY_ID=$($CARDANO_CLI transaction policyid --script-file $SCRIPT_FILE)

section "Token Creation"
read -p 'Token Name ' TOKEN_NAME
read -p 'Token quantity ' TOKEN_QUANTITY

TOKEN_NAME_HEX=$(echo -n "$TOKEN_NAME" | xxd -p)

echo $TOKEN_NAME_HEX

read -p 'Redeemer file name: ' REDEEMER_FILE

REQUIRED_SIGNER_ARRAY=()
SIGNING_KEY_FILE_ARRAY=()
while true; do
read -p 'Add required-signer-hash? [Y/N]: ' input
case $input in
    [yY][eE][sS]|[yY])
        echo "You say Yes"
        read -p 'Input required-signer-hash: ' REQUIRED_SIGNER
        read -p 'Input path to skey: ' SIGNING_KEY_FILE
        REQUIRED_SIGNER_ARRAY+='--required-signer-hash '
        REQUIRED_SIGNER_ARRAY+=$REQUIRED_SIGNER
        REQUIRED_SIGNER_ARRAY+=' '
        SIGNING_KEY_FILE_ARRAY+='--signing-key-file '
        SIGNING_KEY_FILE_ARRAY+=$SIGNING_KEY_FILE
        SIGNING_KEY_FILE_ARRAY+=' '
        ;;
    [nN][oO]|[nN])
        echo "You say No"
        break
        ;;
    *)
        echo "Invalid input..."
        exit 1
        ;;
esac
done

cardano-cli transaction build \
--babbage-era \
--cardano-mode \
--testnet-magic $TESTNET_MAGIC \
--tx-in ${COLLATERAL_TX} \
--tx-out ${TO_WALLET_ADDRESS}+${LOVELACE_TO_SEND}+"${TOKEN_QUANTITY} ${POLICY_ID}.${TOKEN_NAME_HEX}" \
--change-address=${FEE_ADDR} \
--mint="${TOKEN_QUANTITY} ${POLICY_ID}.${TOKEN_NAME_HEX}" \
--mint-script-file ${SCRIPT_FILE} \
--mint-redeemer-file $WORK/datum/${REDEEMER_FILE} \
--protocol-params-file $WORK/transactions/pparams.json \
--out-file $WORK/transactions/tx.draft

# print the cardano transaction build
# cat $build
# execute the cardano transaction build
"${build[@]}"