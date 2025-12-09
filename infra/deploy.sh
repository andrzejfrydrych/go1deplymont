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



#step 2 create logs and Azure container registry - ACR
RG=rg-go1deplymont

#another deploy execution 
az deployment group create \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters acrName=go1deplymontacr

#Step3
#without biceps changes, reparing app in base of local SC and dockerfile:
#az acr credential show --name go1deplymontacr
#credentialls dla ACR
export ACR_NAME=go1deplymontacr
export ACR_SERVER=$(az acr show --name $ACR_NAME --resource-group rg-go1deplymont --query loginServer -o tsv)
echo $ACR_SERVER

az acr login --name $ACR_NAME
#frydrychan@k8s1:~/go1deplymont/infra> echo $ACR_NAME
#go1deplymontacr

cd go1deplymont
docker build -t $ACR_SERVER/go1deplymont:latest .
#Successfully built fd656d59db20
#Successfully tagged go1deplymontacr.azurecr.io/go1deplymont:latest

az acr login --name $ACR_NAME
docker push $ACR_SERVER/go1deplymont:latest
#frydrychan@k8s1:~/go1deplymont> docker push $ACR_SERVER/go1deplymont:latest
#The push refers to repository [go1deplymontacr.azurecr.io/go1deplymont]
#latest: digest: sha256:1737e9e9a3fb977f40fa3e047c0a560edb9861b7df58f9f250fdbc8250aa4e59 size: 3642
