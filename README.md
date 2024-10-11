# Azure Container Apps Album API

Required setup using azure-cli:
```
RESOURCE_GROUP="albumapi-test"
LOCATION="canadacentral"

az login
az bicep install
az group create   --name $RESOURCE_GROUP   --location "$LOCATION"

# deploy the infrastructure
az deployment group create --resource-group $RESOURCE_GROUP --template-file main.bicep

# create a rbac role for github actions to use to deploy updates to the docker container
RESOURCE_GROUP_ID=$(az group list --query "[?name=='$RESOURCE_GROUP'].id" -o tsv)

az ad sp create-for-rbac --name album-api-contributor --role contributor --scopes $RESOURCE_GROUP_ID --json-auth --output json
```

The final command prints a JSON credentials object to be added to the repository secrets for the deployment action to use.
