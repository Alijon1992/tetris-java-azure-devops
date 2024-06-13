#!/bin/bash

# Set variables
RESOURCE_GROUP="rg-tetris"
LOCATION="eastus"
APP_NAME="app-tetris"
PLAN_NAME="myAppServicePlan"
ACR_NAME="acrtetris"
IMAGE_NAME="my-tetris-app:latest"

# Clone the repository
git clone <repository_url>
cd <repository_directory>

# Build the Docker image for the correct platform
docker build --platform=linux/amd64 -t $ACR_NAME.azurecr.io/$IMAGE_NAME .

# Log in to ACR
az acr login --name $ACR_NAME

# Push the Docker image to ACR
docker push $ACR_NAME.azurecr.io/$IMAGE_NAME

# Create a resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create an App Service plan
az appservice plan create --name $PLAN_NAME --resource-group $RESOURCE_GROUP --sku B1 --is-linux

# Create a web app with a Docker container
az webapp create --resource-group $RESOURCE_GROUP --plan $PLAN_NAME --name $APP_NAME --deployment-container-image-name $ACR_NAME.azurecr.io/$IMAGE_NAME

# Enable managed identity for the web app
az webapp identity assign --name $APP_NAME --resource-group $RESOURCE_GROUP

# Get the web app's managed identity principal ID
PRINCIPAL_ID=$(az webapp identity show --name $APP_NAME --resource-group $RESOURCE_GROUP --query principalId --output tsv)

# Get the ACR registry ID
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query id --output tsv)

# Assign the acrpull role to the web app
az role assignment create --assignee $PRINCIPAL_ID --role acrpull --scope $ACR_ID

# Enable ACR admin account (if not already enabled)
az acr update --name $ACR_NAME --admin-enabled true

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv)

# Set the app settings with ACR credentials and port
az webapp config appsettings set --name $APP_NAME --resource-group $RESOURCE_GROUP --settings \
DOCKER_REGISTRY_SERVER_URL=https://$ACR_NAME.azurecr.io \
DOCKER_REGISTRY_SERVER_USERNAME=$ACR_USERNAME \
DOCKER_REGISTRY_SERVER_PASSWORD=$ACR_PASSWORD \
WEBSITES_PORT=80

# Configure the web app to use the container image
az webapp config container set --name $APP_NAME --resource-group $RESOURCE_GROUP --docker-custom-image-name $ACR_NAME.azurecr.io/$IMAGE_NAME --docker-registry-server-url https://$ACR_NAME.azurecr.io --docker-registry-server-user $ACR_USERNAME --docker-registry-server-password $ACR_PASSWORD

echo "Deployment completed successfully."

