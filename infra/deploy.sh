#step 0

az login --use-device-code

#az account list -o table

#Step 1
export RG=rg-go1deplymont
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
export RG=rg-go1deplymont

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

#validation:
az monitor log-analytics workspace list -g $RG -o table
#frydrychan@k8s1:~/go1deplymont> az monitor log-analytics workspace list -g $RG -o table
#CreatedDate                   CustomerId                            Location    ModifiedDate                  Name      ProvisioningState    PublicNetworkAccessForIngestion    PublicNetworkAccessForQuery    ResourceGroup    RetentionInDays
#----------------------------  ------------------------------------  ----------  ----------------------------  --------  -------------------  ---------------------------------  -----------------------------  ---------------  -----------------
#2025-12-09T21:35:54.8684866Z  a33749ee-670e-4742-ac2e-14567fd7297a  westeurope  2025-12-09T21:36:07.0520722Z  go1-logs  Succeeded            Enabled                            Enabled                        rg-go1deplymont  30

az containerapp env list -g $RG -o table
#
#Location     Name     ResourceGroup
#-----------  -------  ---------------
#West Europe  go1-env  rg-go1deplymont


export RG=rg-go1deplymont

az deployment group create \
  --resource-group $RG \
  --template-file infra/main.bicep \
  --parameters acrName=go1deplymontacr \
               appName=go1-app \
               imageRepo=go1deplymont \
               imageTag=latest


#step4 deploy
RG=rg-go1deplymont

az deployment group create \
  --resource-group $RG \
  --template-file infra/main.bicep \
  --parameters acrName=go1deplymontacr \
               appName=go1-app \
               imageRepo=go1deplymont \
               imageTag=latest


az deployment group show \
  --resource-group $RG \
  --name main \
  --query properties.outputs.appFqdn.value \
  -o tsv

  frydrychan@k8s1:~/go1deplymont> az containerapp show \
>   --name go1-app \
>   --resource-group $RG \
>   --query properties.configuration.ingress.fqdn \
>   -o tsv
go1-app.redground-26fb9c0c.westeurope.azurecontainerapps.io

frydrychan@k8s1:~/go1deplymont> az containerapp show \
>   --name go1-app \
>   --resource-group $RG \
>   --query properties.configuration.ingress.fqdn \
>   -o tsv
#will get URL:
#go1-app.redground-26fb9c0c.westeurope.azurecontainerapps.io


#frydrychan@k8s1:~/go1deplymont> wget https://go1-app.redground-26fb9c0c.westeurope.azurecontainerapps.io/notes
#--2025-12-10 01:31:43--  https://go1-app.redground-26fb9c0c.westeurope.azurecontainerapps.io/notes
#Connecting to 10.172.107.13:1080... connected.
#Proxy request sent, awaiting response... 200 OK
#Length: 828 [text/plain]
#Saving to: ‘notes’

#notes                                      100%[=====================================================================================>]     828  --.-KB/s    in 0s

#2025-12-10 01:31:43 (196 MB/s) - ‘notes’ saved [828/828]

#frydrychan@k8s1:~/go1deplymont> cat not
#notatki.txt  notes
#..

#RG=rg-go1deplymont

#read logs:

frydrychan@k8s1:~/go1deplymont> az containerapp show \
>   --name go1-app \
>   --resource-group $RG \
>   -o table
Name     Location     ResourceGroup    Fqdn
-------  -----------  ---------------  -----------------------------------------------------------
go1-app  West Europe  rg-go1deplymont  go1-app.redground-26fb9c0c.westeurope.azurecontainerapps.io

frydrychan@k8s1:~/go1deplymont> az containerapp logs show \
>   --name go1-app \
>   --resource-group $RG \
>   --type system \
>   --tail 50


#clen up 1
# replica = 0 will reduce cpu but logs and env will be still charged.
az containerapp update \
  --name go1-app \
  --resource-group $RG \
  --set template.scale.minReplicas=0

#e.g. remove ACR:
az acr delete \
  --name go1deplymontacr \
  --resource-group $RG \
  --yes

#remove all RG resource group will allow to get with cost to 0
az group delete \
  --name rg-go1deplymont \
  --yes \
  --no-wait