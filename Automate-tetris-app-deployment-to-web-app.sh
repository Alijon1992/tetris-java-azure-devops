#!/bin/bash

# Set variables
RESOURCE_GROUP="rg-tetris-dev-canadacentral-001"
LOCATION="canadacentral"
APP_NAME="app-tetris-dev-canadacentral-001"
PLAN_NAME="asp-tetris-dev-canadacentral-001"
ACR_NAME="acrtetris"
IMAGE_NAME="my-tetris-app:latest"

# Docker install and run?
#Systemctl?

# Build the Docker image for the correct platform
docker build -t acrtetris.azurecr.io/my-tetris-app:latest --platform linux/amd64 .

# Create a resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create the Azure Container Registry with admin enabled
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --location $LOCATION --admin-enabled true

# Log in to ACR
az acr login --name acrtetris

# Push the Docker image to ACR
docker push acrtetris.azurecr.io/my-tetris-app:latest

# Create an App Service plan
az appservice plan create --name $PLAN_NAME --resource-group $RESOURCE_GROUP --sku B1 --is-linux

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv)

# Create a web app with a Docker container
az webapp create --resource-group $RESOURCE_GROUP --plan $PLAN_NAME --name $APP_NAME --container-image-name $ACR_NAME.azurecr.io/$IMAGE_NAME --container-registry-password $ACR_PASSWORD --container-registry-user $ACR_USERNAME

# Configure the web app to use the container image
az webapp config container set --name $APP_NAME --resource-group $RESOURCE_GROUP --docker-custom-image-name $ACR_NAME.azurecr.io/$IMAGE_NAME --docker-registry-server-url https://$ACR_NAME.azurecr.io --docker-registry-server-user $ACR_USERNAME --docker-registry-server-password $ACR_PASSWORD

echo "Deployment completed successfully."

