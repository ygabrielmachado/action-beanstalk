#!/bin/bash

environment=$1

export NVM_DIR=/opt/.nvm
. /opt/.nvm/nvm.sh

mkdir artifact

cd app/

#START CUSTOM CODE

nvm install --lts

node --version

#END CUSTOM CODE

zip -r app.zip .
mv app.zip ../artifact/