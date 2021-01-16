#!/bin/bash

source scriptUtils.sh

. scripts/envVar.sh

export CC_NAME="fabcar"

export FABRIC_CFG_PATH=$PWD/config/

function helper(){
  
  parsePeerConnectionParameters $@
  res=$?
  # verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  CHANNEL_NAME="channel-2"
#   fcn_call='{"function":"queryAllCars","Args":[]}'
#   fcn_call='{"function":"queryCar","Args":["CAR1"]}'
#   fcn_call='{"function":"changeCarOwner","Args":["CAR1","Mike"]}'
  fcn_call='{"function":"createCar","Args":["CAR1","Ford","Mustang","Blue","Arav"]}'
  infoln "invoke fcn call:${fcn_call}"
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} $PEER_CONN_PARMS -c ${fcn_call} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  successln "Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME'"

}

# To invoke chaincode on channel-1
# helper 1 2 3

# To invoke chaincode on channel-2
helper 2 3
