#!/bin/bash

source scriptUtils.sh

CHANNEL_NAME="channel-1"
CHANNEL_NAME2="channel-2"

function startPeers(){
    # if you need to use couch db as state database run 
    # docker-compose -f docker/docker-compose-test-net.yaml -f docker/docker-compose-couch.yaml up -d 2>&1
    docker-compose -f docker/docker-compose-test-net.yaml up -d 2>&1
}

function createArtifacts() {

 infoln "Creating channels with name ${CHANNEL_NAME} and ${CHANNEL_NAME2}"
 echo
 scripts/createChannel.sh $CHANNEL_NAME $CHANNEL_NAME2
  if [ $? -ne 0 ]; then
    fatalln "Create channel failed"
  fi

}

# Start Peer containers
startPeers

# Create channel artifacts and join the respective channel
createArtifacts