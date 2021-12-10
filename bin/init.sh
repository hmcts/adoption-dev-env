#!/usr/bin/env bash

az keyvault secret show --vault-name da-aat -o tsv --query value --name da-local-env-config | base64 -d > .env

if [ -f .env ]
then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

API_DIR=./da-cos-api

az acr login --name hmctspublic --subscription 8999dec3-0104-4a27-94ee-6588559729d1
az acr login --name hmctsprivate --subscription 8999dec3-0104-4a27-94ee-6588559729d1

[[ -d $API_DIR ]] || git clone git@github.com:hmcts/da-cos-api.git

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
