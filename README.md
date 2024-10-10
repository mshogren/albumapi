# Azure Container Apps Album API

Required setup using azure-cli:
```
RESOURCE_GROUP="album-containerapps"
LOCATION="canadacentral"
ENVIRONMENT="env-album-containerapps"
API_NAME="album-api"

az login

az extension add --name containerapp --upgrade --allow-preview true
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights
az provider show -n Microsoft.App

az group create   --name $RESOURCE_GROUP   --location "$LOCATION"
az containerapp env create --name $ENVIRONMENT --resource-group $RESOURCE_GROUP --location "$LOCATION"
az containerapp create --name $API_NAME --resource-group $RESOURCE_GROUP --environment $ENVIRONMENT --target-port 8080 --ingress external --query properties.configuration.ingress.fqdn

az ad sp create-for-rbac --name my-app-credentials --role contributor --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/album-containerapps --json-auth --output json
```

Alternatively using bicep:
```
az bicep install
az group create   --name $RESOURCE_GROUP   --location "$LOCATION"
az deployment group create --resource-group album-containerapps --template-file main.bicep
az ad sp create-for-rbac --name my-app-credentials --role contributor --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/album-containerapps --json-auth --output json
```

In either case the script displays a JSON credentials object to be added to the repository secrets for the deployment action to use.
