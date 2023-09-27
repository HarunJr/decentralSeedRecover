#!/usr/bin/env bash

set -e
set -o pipefail

source helpers.sh

# set -x

# getInputTx $1
# COLLATERAL_TX=${SELECTED_UTXO}
# FROM_WALLET_NAME=${SELECTED_WALLET_NAME}
# FROM_WALLET_ADDRESS=${SELECTED_WALLET_ADDR}
# FROM_BALANCE=${SELECTED_UTXO_LOVELACE}

# section "Select Collateral UTxO"
# read -p 'Collateral wallet name: ' COLLATERAL
# getInputTx ${COLLATERAL}
# COLLATERAL_TX=$SELECTED_UTXO
# FEE_ADDR=$SELECTED_WALLET_ADDR

DATUM_HASH_FILE=$'request-datum.json'
echo $DATUM_HASH_FILE

MINT_REDEEMER_FILE=$'mint-nft-redeemer.json'
echo $MINT_REDEEMER_FILE

REDEEMER_FILE=$'lend-request-redeemer.json'
echo $REDEEMER_FILE


TX_IN_ARRAY=()
while true; do
read -p 'Add Collateral UTxO? [Y/N]: ' input
case $input in
    [yY][eE][sS]|[yY])
        echo "You say Yes"
        read -p 'Wallet name: ' COLLATERAL

        getInputTx ${COLLATERAL}
        COLLATERAL_TX=$SELECTED_UTXO
        FROM_WALLET_ADDRESS=$SELECTED_WALLET_ADDR

        TX_IN_ARRAY+='--tx-in '
        TX_IN_ARRAY+=$COLLATERAL_TX
        TX_IN_ARRAY+=' '
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

TOKENS_SCRIPT_NAME=$'Tokens-Minting'
echo $TOKENS_SCRIPT_NAME

TOKENS_SCRIPT_FILE=$WORK/plutus-scripts/${TOKENS_SCRIPT_NAME}.plutus 
TOKENS_SCRIPT_ADDRESS=$($CARDANO_CLI address build --payment-script-file $TOKENS_SCRIPT_FILE --testnet-magic $TESTNET_MAGIC)
mkdir -p $BASE/.priv/wallets/${TOKENS_SCRIPT_NAME}
echo $TOKENS_SCRIPT_ADDRESS > $BASE/.priv/wallets/${TOKENS_SCRIPT_NAME}/${TOKENS_SCRIPT_NAME}.payment.addr

TOKENS_POLICY_ID=$($CARDANO_CLI transaction policyid --script-file $TOKENS_SCRIPT_FILE)


read -p 'Token to lend ' TOKEN_TO_LEND_NAME
read -p 'Amount of tokens to lend ' TOKEN_AMOUNT
read -p 'Total Amount of Tokens in the wallet ' TOTAL_TOKEN_AMOUNT
CHANGE_TOKENS=$((TOTAL_TOKEN_AMOUNT - TOKEN_AMOUNT))
echo $CHANGE_TOKENS


TOKEN_TO_LEND_HEX=$(echo -n "$TOKEN_TO_LEND_NAME" | xxd -p)

read -p 'Ada to spend: ' ADA
LOVELACE_TO_SPEND=$((ADA * 1000000))

read -p 'Receiving wallet name: ' TO_SCRIPT_NAME

if [[ $TO_SCRIPT_NAME != \addr_* ]];
then 
    TO_WALLET_ADDRESS=$(cat $BASE/.priv/wallets/$TO_SCRIPT_NAME/$TO_SCRIPT_NAME.payment.addr)
else
    TO_WALLET_ADDRESS=$TO_SCRIPT_NAME
fi


SCRIPT_NAME=$'Request'
echo $SCRIPT_NAME

SCRIPT_FILE=$WORK/plutus-scripts/${SCRIPT_NAME}.plutus 
SCRIPT_ADDRESS=$($CARDANO_CLI address build --payment-script-file $SCRIPT_FILE --testnet-magic $TESTNET_MAGIC)
mkdir -p $BASE/.priv/wallets/${SCRIPT_NAME}
echo $SCRIPT_ADDRESS > $BASE/.priv/wallets/${SCRIPT_NAME}/${SCRIPT_NAME}.payment.addr

section "Select Script UTxO"
getInputTx ${SCRIPT_NAME}
SCRIPT_UTXO=$SELECTED_UTXO
PAYMENT=$SELECTED_UTXO_LOVELACE

TO_SCRIPT_NAME_ARRAY=()
DATUM_HASH_ARRAY=()
while true; do
read -p 'Do you want to add additional outputs? [Y/N]: ' input
case $input in
    [yY][eE][sS]|[yY])
        echo "You say Yes"
        read -p 'Ada to send: ' ADA
        LOVELACE_TO_SEND=$((ADA * 1000000))

        # read -p 'Receiving script name: ' TO_SCRIPT_NAME
        TO_SCRIPT_NAME=$'Collateral'
        echo $TO_SCRIPT_NAME

        if [[ $TO_SCRIPT_NAME != \addr_* ]];
        then 
            TO_SCRIPT_ADDRESS=$(cat $BASE/.priv/wallets/$TO_SCRIPT_NAME/$TO_SCRIPT_NAME.payment.addr)
        else
            TO_SCRIPT_ADDRESS=$TO_SCRIPT_NAME
        fi
        echo $TO_SCRIPT_ADDRESS

        SCRIPT_DATUM_HASH_FILE=$WORK/plutus-scripts/${DATUM_HASH_FILE}

        TO_SCRIPT_NAME_ARRAY+='--tx-out '
        TO_SCRIPT_NAME_ARRAY+=$TO_SCRIPT_ADDRESS+$LOVELACE_TO_SEND
        TO_SCRIPT_NAME_ARRAY+=' '
        DATUM_HASH_ARRAY+='--tx-out-datum-hash-file '
        DATUM_HASH_ARRAY+=$SCRIPT_DATUM_HASH_FILE

        # PAYMENT=$(expr $PAYMENT - $LOVELACE_TO_SEND)
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

# read -p 'Receiving script name: ' TO_SCRIPT_NAME

# if [[ $TO_SCRIPT_NAME != \addr_* ]];
# then 
#     TO_WALLET_ADDRESS=$(cat $BASE/.priv/wallets/$TO_SCRIPT_NAME/$TO_SCRIPT_NAME.payment.addr)
# else
#     TO_WALLET_ADDRESS=$TO_SCRIPT_NAME
# fi

MINT_SCRIPT_NAME=$'Lend-Request-Minting'
echo $MINT_SCRIPT_NAME

MINT_SCRIPT_FILE=$WORK/plutus-scripts/${MINT_SCRIPT_NAME}.plutus 
MINT_SCRIPT_ADDRESS=$($CARDANO_CLI address build --payment-script-file $MINT_SCRIPT_FILE --testnet-magic $TESTNET_MAGIC)
mkdir -p $BASE/.priv/wallets/${MINT_SCRIPT_NAME}
echo $MINT_SCRIPT_ADDRESS > $BASE/.priv/wallets/${MINT_SCRIPT_NAME}/${MINT_SCRIPT_NAME}.payment.addr

POLICY_ID=$($CARDANO_CLI transaction policyid --script-file $MINT_SCRIPT_FILE)

section "Token Creation"
TOKEN_NAME=$'LendNFT'
echo $TOKEN_NAME
TOKEN_QUANTITY=$((1))
echo $TOKEN_QUANTITY

# read -p 'Token Name ' TOKEN_NAME
# read -p 'Token quantity ' TOKEN_QUANTITY

TOKEN_NAME_HEX=$(echo -n "$TOKEN_NAME" | xxd -p)


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

INVALID_BEFORE_ARRAY=()
INVALID_HEREAFTER_ARRAY=()
read -p 'Is the script constraint by deadline or time? [Y/N]: ' input
case $input in
    [yY][eE][sS]|[yY])
        ./currentSlot.sh
        echo "You say Yes"
        echo "[X, X+epochs_valid) validity range in slots"
        read -p 'Input the starting validity slot number (X): ' VALIDITY
        # echo 'Current epoch is: ' 
        read -p 'Input the number of epochs for validity (i.e current slot + 200): ' EPOCHS_VALID
        INVALID_BEFORE_ARRAY+='--invalid-before '
        INVALID_BEFORE_ARRAY+=$((VALIDITY))
        INVALID_BEFORE_ARRAY+=' '
        INVALID_HEREAFTER_ARRAY+='--invalid-hereafter '
        INVALID_HEREAFTER_ARRAY+=$((EPOCHS_VALID))
        INVALID_HEREAFTER_ARRAY+=' '
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

# Check if wanted to add additional outputs

$CARDANO_CLI query protocol-parameters --testnet-magic $TESTNET_MAGIC > $WORK/transactions/pparams.json

#Section to allow the new feature for reference scripts

read -p 'Is the script existing in a reference utxo? [Y/N]: ' input
case $input in
    [yY][eE][sS]|[yY])
        ./currentSlot.sh
        echo "You say Yes"
        # echo 'Current epoch is: ' 
        read -p 'Witness wallet name: ' WITNESS
        getInputTx ${WITNESS}
        WITNESS_TX=$SELECTED_UTXO
        # WITNESS_ADDR=$SELECTED_WALLET_ADDR
        # WITNESS_NAME=${SELECTED_WALLET_NAME}

        build=($CARDANO_CLI transaction build \
        --babbage-era \
        --cardano-mode \
        --testnet-magic $TESTNET_MAGIC \
        ${INVALID_BEFORE_ARRAY} ${INVALID_HEREAFTER_ARRAY} \
        --change-address=${FROM_WALLET_ADDRESS} \
        --tx-in ${SCRIPT_UTXO} \
        --spending-tx-in-reference ${WITNESS_TX} \
        --spending-plutus-script-v2 \
        --spending-reference-tx-in-datum-file $WORK/plutus-scripts/${DATUM_HASH_FILE} \
        --spending-reference-tx-in-redeemer-file $WORK/plutus-scripts/${REDEEMER_FILE} \
        --tx-in ${COLLATERAL_TX} \
        --tx-in-collateral=${COLLATERAL_TX} \
        --tx-out ${TO_WALLET_ADDRESS}+${PAYMENT} \
        ${TO_SCRIPT_NAME_ARRAY} \
        ${REQUIRED_SIGNER_ARRAY} \
        --protocol-params-file $WORK/transactions/pparams.json \
        --out-file $WORK/transactions/tx.draft)
        ;;
    [nN][oO]|[nN])
        build=($CARDANO_CLI transaction build \
        --babbage-era \
        --cardano-mode \
        --testnet-magic $TESTNET_MAGIC \
        ${INVALID_BEFORE_ARRAY} ${INVALID_HEREAFTER_ARRAY} \
        ${TX_IN_ARRAY} \
        --tx-in ${SCRIPT_UTXO} \
        --tx-in-script-file ${SCRIPT_FILE} \
        --tx-in-datum-file $WORK/plutus-scripts/${DATUM_HASH_FILE} \
        --tx-in-redeemer-file $WORK/plutus-scripts/${REDEEMER_FILE} \
        --tx-in-collateral=${COLLATERAL_TX} \
        --tx-out ${FROM_WALLET_ADDRESS}+${LOVELACE_TO_SPEND}+"$TOKEN_QUANTITY ${POLICY_ID}.${TOKEN_NAME_HEX}" \
        --tx-out-datum-hash-file $WORK/plutus-scripts/${DATUM_HASH_FILE} \
        --tx-out ${TO_WALLET_ADDRESS}+${LOVELACE_TO_SPEND}+"$TOKEN_AMOUNT ${TOKENS_POLICY_ID}.${TOKEN_TO_LEND_HEX}" \
        --tx-out-datum-hash-file $WORK/plutus-scripts/${DATUM_HASH_FILE} \
        --tx-out ${FROM_WALLET_ADDRESS}+${LOVELACE_TO_SPEND}+"$CHANGE_TOKENS ${TOKENS_POLICY_ID}.${TOKEN_TO_LEND_HEX}" \
        --tx-out-datum-hash-file $WORK/plutus-scripts/${DATUM_HASH_FILE} \
        ${TO_SCRIPT_NAME_ARRAY} ${DATUM_HASH_ARRAY} \
        --mint="$TOKEN_QUANTITY ${POLICY_ID}.${TOKEN_NAME_HEX}" \
        --mint-script-file ${MINT_SCRIPT_FILE} \
        --mint-redeemer-file $WORK/plutus-scripts/${MINT_REDEEMER_FILE} \
        --change-address=${FROM_WALLET_ADDRESS} \
        ${REQUIRED_SIGNER_ARRAY} \
        --protocol-params-file $WORK/transactions/pparams.json \
        --out-file $WORK/transactions/tx.draft)
        ;;
    *)
        echo "Invalid input..."
        exit 1
        ;;
esac

# print the cardano transaction build
# cat $build
# execute the cardano transaction build
"${build[@]}"

$CARDANO_CLI transaction sign \
--tx-body-file $WORK/transactions/tx.draft \
${SIGNING_KEY_FILE_ARRAY} \
--testnet-magic $TESTNET_MAGIC \
--out-file $WORK/transactions/tx.signed \

$CARDANO_CLI transaction submit --tx-file $WORK/transactions/tx.signed --testnet-magic $TESTNET_MAGIC
    

cat $build