#!/usr/bin/env bash

set -e
set -o pipefail

source helpers.sh

if [ -z "$1" ]; then
    >&2 echo "expected name as argument"
    exit 1
fi

path=$WALLETS/$1
mkdir -p "$path"

vkey="$path/$1.vkey"
skey="$path/$1.skey"
addr="$path/$1.payment.addr"

if [ -f "$vkey" ]; then
    >&2 echo "verification key file $vkey already exists"
    exit 1
fi

if [ -f "$skey" ]; then
    >&2 echo "signing key file $skey already exists"
    exit 1
fi

if [ -f "$addr" ]; then
    >&2 echo "address file $addr already exists"
    exit 1
fi

key_build=($CARDANO_CLI address key-gen \
--verification-key-file "$vkey" \
--signing-key-file "$skey")

address_build=($CARDANO_CLI address build \
--payment-verification-key-file "$vkey" \
$TESTNET_MAGIC --out-file "$addr")

# print the cardano transaction build
# cat $build
# execute the cardano transaction build
"${key_build[@]}"
"${address_build[@]}"

echo "wrote verification key to: $vkey"
echo "wrote signing key to: $skey"
echo "wrote address to: $addr"
echo "wrote testnet to: $TESTNET_MAGIC"

cat $key_build
cat $address_build
