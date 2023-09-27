#!/usr/bin/env bash
set -e
set -o pipefail

. "$(dirname $0)"/env # soure env variables
$CARDANO_CLI query tip $PREPROD_TESTNET | jq -r '.slot'