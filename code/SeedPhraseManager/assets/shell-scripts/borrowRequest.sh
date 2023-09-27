#!/usr/bin/env bash

set -e
set -o pipefail

set -x

source helpers.sh
getInputTx $1
FROM_UTXO=${SELECTED_UTXO}
FROM_WALLET_NAME=${SELECTED_WALLET_NAME}
FROM_WALLET_ADDRESS=${SELECTED_WALLET_ADDR}
FROM_BALANCE=${SELECTED_UTXO_LOVELACE}
echo $FROM_WALLET_NAME

FROM_UTXO_ARRAY=()
while true; do
read -p 'Add Collateral UTxO? [Y/N]: ' input
case $input in
    [yY][eE][sS]|[yY])
        echo "You say Yes"
      #   read -p 'Collateral wallet name: ' COLLATERAL

        getInputTx ${FROM_WALLET_NAME}
        COLLATERAL_TX=$SELECTED_UTXO
        FROM_WALLET_ADDRESS=$SELECTED_WALLET_ADDR

        FROM_UTXO_ARRAY+='--tx-in '
        FROM_UTXO_ARRAY+=$COLLATERAL_TX
        FROM_UTXO_ARRAY+=' '
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

read -p 'Enter Collateral for loan in Ada: ' ADA
LOVELACE_TO_SEND=$((ADA * 1000000))
echo $LOVELACE_TO_SEND


LOVELACE_FOR_MINT=$((2000000))
echo $LOVELACE_FOR_MINT


# read -p 'Receiving script name: ' SCRIPT_NAME
SCRIPT_NAME=$'Request'
echo $SCRIPT_NAME

if [[ $SCRIPT_NAME != \addr_* ]];
then 
    SCRIPT_ADDRESS=$($CARDANO_CLI address build --payment-script-file $WORK/plutus-scripts/${SCRIPT_NAME}.plutus --testnet-magic $TESTNET_MAGIC)
    mkdir -p $BASE/.priv/wallets/preview/${SCRIPT_NAME}
    echo $SCRIPT_ADDRESS > $BASE/.priv/wallets/preview/${SCRIPT_NAME}/${SCRIPT_NAME}.payment.addr
else
    SCRIPT_ADDRESS=$SCRIPT_NAME
fi

DATUM_HASH_FILE=$'request-datum.json'
echo $DATUM_HASH_FILE

MINT_SCRIPT_NAME=$'Borrow-Request-Minting'
echo $MINT_SCRIPT_NAME

MINT_SCRIPT_FILE=$WORK/plutus-scripts/${MINT_SCRIPT_NAME}.plutus 
MINT_SCRIPT_ADDRESS=$($CARDANO_CLI address build --payment-script-file $MINT_SCRIPT_FILE  --testnet-magic $TESTNET_MAGIC)
mkdir -p $BASE/.priv/wallets/preview/${MINT_SCRIPT_NAME}
echo $MINT_SCRIPT_ADDRESS > $BASE/.priv/wallets/preview/${MINT_SCRIPT_NAME}/${MINT_SCRIPT_NAME}.payment.addr

POLICY_ID=$($CARDANO_CLI transaction policyid --script-file $MINT_SCRIPT_FILE)

section "Token Creation"
TOKEN_NAME=$'BorrowNFT'
echo $TOKEN_NAME
TOKEN_QUANTITY=$((1))
echo $TOKEN_QUANTITY

# read -p 'Token Name ' TOKEN_NAME
# read -p 'Token quantity ' TOKEN_QUANTITY

TOKEN_NAME_HEX=$(echo -n "$TOKEN_NAME" | xxd -p)

# read -p 'Redeemer file name: ' REDEEMER_FILE
REDEEMER_FILE=$'mint-redeemer.json'
echo $REDEEMER_FILE

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

build=($CARDANO_CLI transaction build \
--babbage-era \
--cardano-mode \
--testnet-magic $TESTNET_MAGIC  \
--tx-in ${FROM_UTXO} \
${FROM_UTXO_ARRAY} \
--tx-out ${SCRIPT_ADDRESS}+${LOVELACE_TO_SEND} \
--tx-out-datum-hash-file $WORK/datum/${DATUM_HASH_FILE} \
--mint="$TOKEN_QUANTITY ${POLICY_ID}.${TOKEN_NAME_HEX}" \
--mint-script-file ${MINT_SCRIPT_FILE} \
--mint-redeemer-file $WORK/redeemer/${REDEEMER_FILE} \
--tx-out ${FROM_WALLET_ADDRESS}+${LOVELACE_FOR_MINT}+"$TOKEN_QUANTITY ${POLICY_ID}.${TOKEN_NAME_HEX}" \
--tx-out-datum-hash-file $WORK/datum/${DATUM_HASH_FILE} \
--tx-in-collateral=${FROM_UTXO} \
--change-address=${FROM_WALLET_ADDRESS} \
${REQUIRED_SIGNER_ARRAY} \
--protocol-params-file $WORK/transactions/pparams.json \
--out-file $WORK/transactions/tx.draft)

"${build[@]}"

TX_HASH=$($CARDANO_CLI transaction txid --tx-body-file $WORK/transactions/tx.draft)
# TX_ANALYZE=$($CARDANO_CLI transaction view --tx-body-file $WORK/transactions/tx.draft)

echo 'Transaction with id: ' $TX_HASH
echo 'Lovelace to Send: ' ${LOVELACE_TO_SEND}
echo 'Lovelace to Mint: ' ${LOVELACE_FOR_MINT}

# echo 'User transaction with id: ' $TX_ANALYZE
read -p 'Sign and submit Pay to Script Tx? [Y/N]: ' input

case $input in
      [yY][eE][sS]|[yY])
            echo "You say Yes"
            $CARDANO_CLI transaction sign \
            --tx-body-file $WORK/transactions/tx.draft \
            --signing-key-file $BASE/.priv/wallets/preview/${FROM_WALLET_NAME}/${FROM_WALLET_NAME}.skey \
            --testnet-magic $TESTNET_MAGIC \
            --out-file $WORK/transactions/tx.signed

            $CARDANO_CLI transaction submit \
            --tx-file $WORK/transactions/tx.signed \
            --testnet-magic $TESTNET_MAGIC
            ;;
      [nN][oO]|[nN])
            echo "You say No"
            ;;
      *)
            echo "Invalid input..."
            exit 1
            ;;
esac

section "Creating reference script"
read -p 'Do you want to create reference script? [Y/N]: ' input

case $input in
      [yY][eE][sS]|[yY])
            echo "You say Yes"
            read -p 'Select the key witness wallet name: ' WITNESS
            getInputTx ${WITNESS}
            WITNESS_TX=$SELECTED_UTXO
            WITNESS_ADDR=$SELECTED_WALLET_ADDR
            WITNESS_NAME=${SELECTED_WALLET_NAME}
            read -p 'lovelace to cover the transaction and the reference script: ' LOVELACE_TO_SEND

            # Validate the transaction
            txOutRefId=${WITNESS_TX::-2}
            echo txOutRefId

            if [[ $TX_HASH == $txOutRefId ]];
            then 
                  SCRIPT_FILE=$WORK/plutus-scripts/${SCRIPT_NAME}.plutus 

                  $CARDANO_CLI transaction build \
                  --tx-in ${WITNESS_TX} \
                  --tx-out ${WITNESS_ADDR}+${LOVELACE_TO_SEND} \
                  --tx-out-reference-script-file ${SCRIPT_FILE} \
                  --change-address=${WITNESS_ADDR} \
                  --testnet-magic ${TESTNET_MAGIC}  \
                  --out-file $WORK/transactions/tx.draft \
                  --babbage-era
            else
                  echo "Invalid input..."
                  exit 1
            fi

            read -p 'Sign and submit creation of reference script? [Y/N]: ' input

            case $input in
                  [yY][eE][sS]|[yY])
                        echo "You say Yes"
                        $CARDANO_CLI transaction sign \
                        --tx-body-file $WORK/transactions/tx.draft \
                        --signing-key-file $BASE/.priv/wallets/preview/${WITNESS_NAME}/${WITNESS_NAME}.payment.skey \
                        --testnet-magic $TESTNET_MAGIC \
                        --out-file $WORK/transactions/tx.signed

                        $CARDANO_CLI transaction submit --tx-file $WORK/transactions/tx.signed --testnet-magic $TESTNET_MAGIC

                        ;;
                  [nN][oO]|[nN])
                        echo "You say No"
                        ;;
                  *)
                        echo "Invalid input..."
                        exit 1
                        ;;
            esac

            ;;
      [nN][oO]|[nN])
            echo "You say No"
            ;;
      *)
            echo "Invalid input..."
            exit 1
            ;;
esac
