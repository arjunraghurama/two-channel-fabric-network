#!/bin/bash

function startService()
{
    ./createCertificatesAndRegisterUsers.sh
    ./createPeersAndCreateChannel.sh
}

startService