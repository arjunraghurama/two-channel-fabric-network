#!/bin/bash

CHANNEL_NAME=${1:-"channel-1"}
CHANNEL_NAME2=${2:-"channel-2"}
CC_NAME=${3:-"fabcar"}
CC_VERSION=${4:-"1.0"}
CC_SRC_LANGUAGE=${5:-"java"}
CC_SRC_PATH=${6:-"./smart-contract"}

function deploySmartContract() {

 infoln "Deploying chaincode on the peers.."
 echo
 scripts/deployCC.sh $CHANNEL_NAME $CHANNEL_NAME2 $CC_NAME $CC_VERSION $CC_SRC_LANGUAGE $CC_SRC_PATH
  if [ $? -ne 0 ]; then
    fatalln "Deploy chaincode failed"
  fi

}

deploySmartContract