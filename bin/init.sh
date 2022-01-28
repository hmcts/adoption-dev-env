#!/usr/bin/env bash

az keyvault secret show --vault-name adoption-aat -o tsv --query value --name adoption-local-env-config | base64 -d > .env

if [ -f .env ]
then
 export $(cat .env | sed 's/#.*//g' | xargs)
fi

API_DIR=./adoption-cos-api

az acr login --name hmctspublic --subscription 1c4f0704-a29e-403d-b719-b90c34ef14c9
az acr login --name hmctsprivate --subscription 1c4f0704-a29e-403d-b719-b90c34ef14c9

[[ -d $API_DIR ]] || git clone git@github.com:hmcts/adoption-cos-api.git

docker-compose stop
docker-compose pull
docker-compose up -d idam-api fr-am fr-idm idam-web-public shared-db

./bin/wait-for.sh "IDAM" http://localhost:5000

echo "Starting IDAM set up"

./bin/idam-setup.sh

cd $API_DIR && (./gradlew assemble -q > /dev/null 2>&1)

cd ../

docker-compose up --build -d

cd $API_DIR

./gradlew -q generateCCDConfig
../bin/wait-for.sh "CCD definition store" http://localhost:4451

./bin/add-roles.sh
./bin/add-ccd-user-profiles.sh
../bin/add-role-assignments.sh
./bin/process-and-import-ccd-definition.sh
cd ../
