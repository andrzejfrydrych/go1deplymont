#step 0

az login --use-device-code

#az account list -o table

#Step 1
RG=rg-go1deplymont
LOCATION=westeurope

az group create \
  --name $RG \
  --location $LOCATION

# step 1
#
export RG=rg-go1deplymont

az deployment group create \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters acrName=go1deplymontacr

az acr show -g $RG -n rg-go1deplymont -o table


