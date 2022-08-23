#!/usr/bin/env bash

#### Set these variables ####################################

# Your Control Hub Org ID
SCH_ORG_ID=

# If using StreamSets Cloud use https://cloud.streamsets.com 
SCH_URL=https://na01.hub.streamsets.com

# Control Hub API Cred ID
SCH_CRED_ID=

#  Control Hub API Cred Token
SCH_CRED_TOKEN=

# The namespace to be used (The namespace will be created if it does not exist)
KUBE_NAMESPACE=

##  End of user variables ####################################

#### Create Namespace
kubectl create namespace ${KUBE_NAMESPACE}

#### Set Context
kubectl config set-context $(kubectl config current-context) --namespace=${KUBE_NAMESPACE}

#### Create a lower-cased UUID
SDC_ID=`uuidgen | tr "[:upper:]" "[:lower:]"`

#### Store the sdc-id in a secret
kubectl create secret generic sdc-id --from-literal=sdc.id=${SDC_ID}

#### Get an auth token for SDC and store it in a secret

# Get an SDC auth token from Control Hub
SDC_AUTH_TOKEN_RESPONSE=$(curl -s -X PUT -d "{\"organization\": \"${SCH_ORG_ID}\", \"componentType\" : \"dc\", \"numberOfComponents\" : 1, \"active\" : true}" ${SCH_URL}/security/rest/v1/organization/${SCH_ORG_ID}/components -H "Content-Type:application/json" -H "X-Requested-By:curl" -H "X-SS-REST-CALL:true" -H "X-SS-App-Component-Id: $SCH_CRED_ID" -H "X-SS-App-Auth-Token: $SCH_CRED_TOKEN")

# Uncomment this line to view the full SDC_AUTH_TOKEN_RESPONSE
# echo "SDC_AUTH_TOKEN_RESPONSE "${SDC_AUTH_TOKEN_RESPONSE}

# Use jq to extract just the SDC auth token from full auth token response
SDC_AUTH_TOKEN=$( echo ${SDC_AUTH_TOKEN_RESPONSE} | jq '.[0].fullAuthToken')

# Uncomment this line to view the SDC_AUTH_TOKEN
# echo "SDC_AUTH_TOKEN "${SDC_AUTH_TOKEN}

if [ -z "$SDC_AUTH_TOKEN" ]; then
  echo "Failed to generate SDC token."
  exit 1
fi
echo "Generated an Auth Token for SDC"

# Store the SDC auth token in a secret
kubectl create secret generic sdc-auth-token --from-literal=application-token.txt=${SDC_AUTH_TOKEN}

#### Deploy ConfigMap for dpm.properties
kubectl apply -f yaml/dpm-configmap.yaml

#### Create SDC Deployment and Service
kubectl apply -f yaml/sdc.yaml

