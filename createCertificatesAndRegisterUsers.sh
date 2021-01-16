#!/bin/bash

source scriptUtils.sh

export FABRIC_CFG_PATH=${PWD}/configtx

function createCertificateAuthorities(){

    infoln "Creating certificates using Fabric Crtificate Authority"

    docker-compose -f docker/docker-compose-ca.yaml up -d 2>&1

    . organizations/fabric-ca/registerEnroll.sh

    while :
        do
        if [ ! -f "organizations/fabric-ca/org1/tls-cert.pem" ]; then
            sleep 1
        else
            break
        fi
        done

    infoln "Create Org1 Identities"

    createOrg1

    infoln "Create Org2 Identities"

    createOrg2

    infoln "Create Org3 Identities"

    createOrg3

    infoln "Create Orderer Org Identities"

    createOrderer

  infoln "Generate CCP files for Org1,Org2 and Org3"
  ./organizations/ccp-generate.sh

}

function createConsortium() {

  which configtxgen
  if [ "$?" -ne 0 ]; then
    fatalln "Configtxgen tool not found."
  fi

  infoln "Generating Orderer Genesis block"

  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
  set -x
  configtxgen -profile OrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    fatalln "Failed to generate orderer genesis block..."
  fi
  successln "Created Genesis block"
}

# Create Certificate authority docker containers
createCertificateAuthorities

# Create consortium 
createConsortium