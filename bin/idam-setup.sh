#!/usr/bin/env bash

if [ -f .env ]
then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

IDAM_URI="http://localhost:5000"

REDIRECTS=("http://localhost:3000/oauth2/callback")
REDIRECTS_STR=$(printf "\"%s\"," "${REDIRECTS[@]}")
REDIRECT_URI="[${REDIRECTS_STR%?}]"

CCD_REDIRECTS=("http://ccd-data-store-api/oauth2redirect")
CCD_REDIRECTS_STR=$(printf "\"%s\"," "${CCD_REDIRECTS[@]}")
CCD_REDIRECT_URI="[${CCD_REDIRECTS_STR%?}]"

AM_REDIRECTS=("http://am-role-assignment-service:4096/oauth2redirect")
AM_REDIRECTS_STR=$(printf "\"%s\"," "${AM_REDIRECTS[@]}")
AM_REDIRECT_URI="[${AM_REDIRECTS_STR%?}]"

DA_CLIENT_ID="da"
XUI_CLIENT_ID="xuiwebapp"

DA_CLIENT_SECRET=${OAUTH2_CLIENT_SECRET}
XUI_CLIENT_SECRET=${OAUTH2_CLIENT_SECRET}

ROLES_ARR=("ccd-import" "caseworker-da" "caseworker" "caseworker-da-courtadmin" "caseworker-da-systemupdate" "caseworker-da-superuser" "caseworker-da-la" "caseworker-da-judge" "caseworker-da-solicitor")
ROLES_STR=$(printf "\"%s\"," "${ROLES_ARR[@]}")
ROLES="[${ROLES_STR%?}]"

XUI_ROLES_ARR=("XUI-Admin" "XUI-SuperUser" "caseworker" "caseworker-da" "caseworker-da-courtadmin" "caseworker-da-systemupdate" "caseworker-da-superuser" "caseworker-da-la" "caseworker-da-judge" "caseworker-da-solicitor")
XUI_ROLES_STR=$(printf "\"%s\"," "${XUI_ROLES_ARR[@]}")
XUI_ROLES="[${XUI_ROLES_STR%?}]"

AUTH_TOKEN=$(curl -s -H 'Content-Type: application/x-www-form-urlencoded' -XPOST "${IDAM_URI}/loginUser?username=idamOwner@hmcts.net&password=Ref0rmIsFun" | docker run --rm --interactive stedolan/jq -r .api_auth_token)
HEADERS=(-H "Authorization: AdminApiAuthToken ${AUTH_TOKEN}" -H "Content-Type: application/json")

echo "Setup domestic abuse client"
# Create a client
curl -s -o /dev/null -XPOST "${HEADERS[@]}" ${IDAM_URI}/services \
 -d '{ "activationRedirectUrl": "", "allowedRoles": '"${ROLES}"', "description": "'${DA_CLIENT_ID}'", "label": "'${DA_CLIENT_ID}'", "oauth2ClientId": "'${DA_CLIENT_ID}'", "oauth2ClientSecret": "'${DA_CLIENT_SECRET}'", "oauth2RedirectUris": '${REDIRECT_URI}', "oauth2Scope": "openid profile roles", "onboardingEndpoint": "string", "onboardingRoles": '"${ROLES}"', "selfRegistrationAllowed": true}'

echo "Setup xui client"
# Create a client
curl -s -o /dev/null -XPOST "${HEADERS[@]}" ${IDAM_URI}/services \
 -d '{ "activationRedirectUrl": "", "allowedRoles": '"${XUI_ROLES}"', "description": "'${XUI_CLIENT_ID}'", "label": "'${XUI_CLIENT_ID}'", "oauth2ClientId": "'${XUI_CLIENT_ID}'", "oauth2ClientSecret": "'${XUI_CLIENT_SECRET}'", "oauth2RedirectUris": '${REDIRECT_URI}', "oauth2Scope": "profile openid roles manage-user create-user search-user", "onboardingEndpoint": "string", "onboardingRoles": '"${XUI_ROLES}"', "selfRegistrationAllowed": true}'

echo "Setup ccd data store client"
curl -s -o /dev/null -XPOST "${HEADERS[@]}" ${IDAM_URI}/services \
 -d '{ "activationRedirectUrl": "", "allowedRoles": '"${ROLES}"', "description": "ccd_data_store_api", "label": "ccd_data_store_api", "oauth2ClientId": "ccd_data_store_api", "oauth2ClientSecret": "'${OAUTH2_CLIENT_SECRET}'", "oauth2RedirectUris": '${CCD_REDIRECT_URI}', "oauth2Scope": "profile openid roles manage-user", "onboardingEndpoint": "string", "onboardingRoles": '"${ROLES}"', "selfRegistrationAllowed": true}'

echo "Setup access management client"
curl -s -o /dev/null -XPOST "${HEADERS[@]}" ${IDAM_URI}/services \
 -d '{ "activationRedirectUrl": "", "allowedRoles": '"${ROLES}"', "description": "am_role_assignment", "label": "am_role_assignment", "oauth2ClientId": "am_role_assignment", "oauth2ClientSecret": "am_role_assignment_secret", "oauth2RedirectUris": '${AM_REDIRECT_URI}', "oauth2Scope": "profile openid roles search-user", "onboardingEndpoint": "string", "onboardingRoles": '"${ROLES}"', "selfRegistrationAllowed": true}'

echo "Setup domestic abuse roles"
# Create roles in idam
for role in "${ROLES_ARR[@]}"; do
  curl -s -o /dev/null -XPOST ${IDAM_URI}/roles "${HEADERS[@]}" \
    -d '{"id": "'${role}'","name": "'${role}'","description": "'${role}'","assignableRoles": [],"conflictingRoles": []}'
done

echo "Setup xui roles"
# Create roles in idam
for role in "${XUI_ROLES_ARR[@]}"; do
  curl -s -o /dev/null -XPOST ${IDAM_URI}/roles "${HEADERS[@]}" \
    -d '{"id": "'${role}'","name": "'${role}'","description": "'${role}'","assignableRoles": [],"conflictingRoles": []}'
done

echo "Setup doemstic abuse client roles"
# Assign all the roles to the client
curl -s -o /dev/null -XPUT "${HEADERS[@]}" ${IDAM_URI}/services/${DA_CLIENT_ID}/roles -d "${ROLES}"

echo "Setup xui client roles"
# Assign all the roles to the client
curl -s -o /dev/null -XPUT "${HEADERS[@]}" ${IDAM_URI}/services/${XUI_CLIENT_ID}/roles -d "${XUI_ROLES}"

echo "Creating idam users"
./bin/idam-create-user.sh caseworker,caseworker-divorce,caseworker-divorce-courtadmin_beta,caseworker-divorce-systemupdate,caseworker-divorce-courtadmin,caseworker-divorce-bulkscan,caseworker-divorce-superuser,caseworker-divorce-courtadmin-la $IDAM_CASEWORKER_USERNAME $IDAM_CASEWORKER_PASSWORD caseworker
./bin/idam-create-user.sh caseworker,caseworker-divorce,caseworker-divorce-courtadmin_beta $IDAM_TEST_CASEWORKER_USERNAME $IDAM_TEST_CASEWORKER_PASSWORD caseworker
./bin/idam-create-user.sh caseworker,caseworker-divorce,caseworker-divorce-solicitor,caseworker-divorce-superuser $IDAM_TEST_SOLICITOR_USERNAME $IDAM_TEST_SOLICITOR_PASSWORD caseworker
./bin/idam-create-user.sh ccd-import $DEFINITION_IMPORTER_USERNAME $DEFINITION_IMPORTER_PASSWORD Default
./bin/idam-create-user.sh caseworker,caseworker-divorce,caseworker-divorce-systemupdate $IDAM_SYSTEM_UPDATE_USERNAME $IDAM_SYSTEM_UPDATE_PASSWORD caseworker
./bin/idam-create-user.sh caseworker $CCD_SYSTEM_UPDATE_USERNAME $CCD_SYSTEM_UPDATE_PASSWORD caseworker
echo "Idam setup complete"