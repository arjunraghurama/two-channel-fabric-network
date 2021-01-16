#!/bin/bash

source scriptUtils.sh

CHANNEL_NAME="$1"
CHANNEL_NAME2="$2"
DELAY="$3"
MAX_RETRY="$4"
VERBOSE="$5"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

# import utils
. scripts/envVar.sh

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelTx() {

	set -x
	configtxgen -profile ThreeOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
	res=$?
	{ set +x; } 2>/dev/null
	if [ $res -ne 0 ]; then
		fatalln "Failed to generate channel configuration transaction..."
	fi

}

createChannelTx2() {

	set -x
	configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME2}.tx -channelID $CHANNEL_NAME2
	res=$?
	{ set +x; } 2>/dev/null
	if [ $res -ne 0 ]; then
		fatalln "Failed to generate channel configuration transaction..."
	fi

}

createAnchorPeerTx() {

	for orgmsp in Org1MSP Org2MSP Org3MSP; do

	infoln "Generating anchor peer update transaction for ${orgmsp}"
	set -x
	configtxgen -profile ThreeOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/ChannelOne${orgmsp}anchors.tx -channelID $CHANNEL_NAME -asOrg ${orgmsp}
	res=$?
	{ set +x; } 2>/dev/null
	if [ $res -ne 0 ]; then
		fatalln "Failed to generate anchor peer update transaction for ${orgmsp}..."
	fi
	done
}

createAnchorPeerTx2() {

	for orgmsp in Org2MSP Org3MSP; do

	infoln "Generating anchor peer update transaction for ${orgmsp}"
	set -x
	configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/ChannelTwo${orgmsp}anchors.tx -channelID $CHANNEL_NAME2 -asOrg ${orgmsp}
	res=$?
	{ set +x; } 2>/dev/null
	if [ $res -ne 0 ]; then
		fatalln "Failed to generate anchor peer update transaction for ${orgmsp}..."
	fi
	done
}

createChannel() {
	setGlobals 1
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel create -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.example.com -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
	successln "Channel '$CHANNEL_NAME' created"
}

createChannel2() {
	setGlobals 2
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel create -o localhost:7050 -c $CHANNEL_NAME2 --ordererTLSHostnameOverride orderer.example.com -f ./channel-artifacts/${CHANNEL_NAME2}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME2}.block --tls --cafile $ORDERER_CA >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
	successln "Channel '$CHANNEL_NAME2' created"
}

# queryCommitted ORG
joinChannel() {
  ORG=$1
  setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

joinChannel2() {
  ORG=$1
  setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME2.block >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME2' "
}

updateAnchorPeers() {
  ORG=$1
  setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
		peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ./channel-artifacts/ChannelOne${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
  verifyResult $res "Anchor peer update failed"
  successln "Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"
  sleep $DELAY
}

updateAnchorPeers2() {
  ORG=$1
  setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
		peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME2 -f ./channel-artifacts/ChannelTwo${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
  verifyResult $res "Anchor peer update failed"
  successln "Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME2'"
  sleep $DELAY
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}

function channelOne(){
	export FABRIC_CFG_PATH=${PWD}/configtx
	### channel-1 artifacts
	## Create channeltx
	infoln "Generating channel create transaction '${CHANNEL_NAME}.tx'"
	createChannelTx

	## Create anchorpeertx
	infoln "Generating anchor peer update transactions"
	createAnchorPeerTx

	export FABRIC_CFG_PATH=$PWD/config/

	## Create channel-1
	infoln "Creating channel ${CHANNEL_NAME}"
	createChannel

	## Join all the peers to the channel
	infoln "Join Org1 peers to the channel..."
	joinChannel 1
	infoln "Join Org2 peers to the channel..."
	joinChannel 2
	infoln "Join Org3 peers to the channel..."
	joinChannel 3

	## Set the anchor peers for each org in the channel
	infoln "Updating anchor peers for org1..."
	updateAnchorPeers 1
	infoln "Updating anchor peers for org2..."
	updateAnchorPeers 2
	infoln "Updating anchor peers for org3..."
	updateAnchorPeers 3

	successln "channel-1 successfully joined"
}

function channelTwo(){
	export FABRIC_CFG_PATH=${PWD}/configtx
	### channel-2 artifacts
	## Create channeltx
	infoln "Generating channel create transaction '${CHANNEL_NAME2}.tx'"
	createChannelTx2

	## Create anchorpeertx
	infoln "Generating anchor peer update transactions"
	createAnchorPeerTx2

	export FABRIC_CFG_PATH=$PWD/config2/

	## Create channel-2
	infoln "Creating channel ${CHANNEL_NAME2}"
	createChannel2

	## Join all the peers to the channel
	infoln "Join Org2 peers to the channel..."
	joinChannel2 2
	infoln "Join Org3 peers to the channel..."
	joinChannel2 3

	## Set the anchor peers for each org in the channel
	infoln "Updating anchor peers for org2..."
	updateAnchorPeers2 2
	infoln "Updating anchor peers for org3..."
	updateAnchorPeers2 3

	successln "channel-2 successfully joined"
}

channelOne

channelTwo

exit 0
