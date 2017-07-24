#!/usr/bin/env bash -ue
########################################################
#### Change the following to customize your install ####
########################################################

## this will be the name of the resource group and the VM + all other compoents will use this as the base of their names
baseName='dockerBuild'

## for testing and rapidly creating multiple versions for tutorials or testing. Script will create something like dockerBuild01 <- given a suffix of 01 and a baseName of dockerBuild
versionSuffix=''

## The Azure location for your resources
location='westus'

## Your Azure account name.
azureAccountName='Niigata-Ken'

## VM Admin user information
username='dockeruser'

## Custom DNS name
customDnsBase='ehimeprefecture.com'


########################################################
#### The remainder can be changed but not required  ####
########################################################

## DNS names and storage account names can't have upppercase letters
baseNameLower=$(echo -e "${baseName}" |tr '[:upper:]' '[:lower:]')

echo -e '[info] basenamelower'
echo -e "[info] ${baseNameLower}"

## Resource group info
rgName="${baseName}${versionSuffix}"

## Set variables for VNet
vnetName="${baseName}vnet"
vnetPrefix='10.0.0.0/16'
subnetName='default'
subnetPrefix='10.0.0.0/24'

## Set variables for storage
stdStorageAccountName="${baseNameLower}storage${versionSuffix}"

## Set variables for VM
vmSize='Standard_DS1_V2'
publisher='Canonical'
offer='UbuntuServer'
sku='16.04.0-LTS'
version='latest'
vmName="${baseName}"
nicName="${baseName}NIC"
privateIPAddress='10.0.0.4'
pipName="${baseName}-ip"
nsgName="${baseName}-nsg"
osDiskName='osdisk'

## VM Admin user information
adminKeyPairName="id_${vmName}_rsa"

#DNS Naming
dnsName="${baseNameLower}system${versionSuffix}"
fullDnsName="${dnsName}.${location}.cloudapp.azure.com"
customDnsName="${baseNameLower}.${customDnsBase}"

## Where to place the remote Docker Host TLS certs
tlsCertLocation="./certs/${rgName}"
rsaKeysLocation="./keys/${rgName}"


########################################################
#### The script actually begins...                  ####
########################################################

## TODO: the Docker running/stopped/non-existant code could use updating
RUNNING=$(docker inspect --format="{{ .State.Running }}" azureCli 2> /dev/null)

if [ $? -eq 1 ] ; then
  echo -e '[warn] azureCli container does not exist. Executing docker run'
  docker run -td --name azureCli -v "${PWD}:/config microsoft/azure-cli"

  docker exec -it azureCli azure login
fi

if [ "${RUNNING}" == false ] ; then
  echo -e '[warn] azureCli is not running. Executing docker start'

  docker start azureCli ## should START here
  docker exec -it azureCli azure login
fi

## Please store the private key securely once this is done!
echo -e "[info] Creating admin SSH keypair: ${rsaKeysLocation}/${adminKeyPairName}"
echo -e '[warn] Security Risk, guard this with your LIFE!!!'

mkdir -p "${rsaKeysLocation}"

ssh-keygen                                    \
  -t rsa                                      \
  -b 2048                                     \
  -C "${username}@Azure-${rgName}-${vmName}"  \
  -f "${rsaKeysLocation}/${adminKeyPairName}" \
  -q                                          \
  -N ''

set -x && \
docker exec -it azureCli azure account set "${azureAccountName}"

echo -e "[info] Create resource group"

# Create Resource Group
docker exec -it azureCli azure group create $rgName $location

echo -e "[info] Create  VNET"
docker exec -it azureCli azure network vnet create        \
  --resource-group $rgName                                \
  --name $vnetName                                        \
  --address-prefixes $vnetPrefix                          \
  --location $location

echo -e "[info] Create  Subnet"
docker exec -it azureCli azure network vnet subnet create \
  --resource-group $rgName                                \
  --vnet-name $vnetName                                   \
  --name $subnetName                                      \
  --address-prefix $subnetPrefix

echo -e "[info] Create Public IP"
docker exec -it azureCli azure network public-ip create   \
  --resource-group $rgName                                \
  --name $pipName                                         \
  --location $location                                    \
  --allocation-method Static                              \
  --domain-name-label $dnsName                            \
  --idle-timeout 4 \
  --ip-version IPv4

echo -e "[info] Create NIC"
docker exec -it azureCli azure network nic create         \
  --name $nicName                                         \
  --resource-group $rgName                                \
  --location $location                                    \
  --private-ip-address $privateIPAddress                  \
  --subnet-vnet-name $vnetName                            \
  --public-ip-name $pipName                               \
  --subnet-name default

echo -e "[info] Create network security group"
docker exec -it azureCli azure network nsg create         \
  --resource-group $rgName                                \
  --name $nsgName                                         \
  --location $location

echo -e "[info] Create inbound security rules"

echo -e "=> Create allow-ssh rule"
docker exec -it azureCli azure network nsg rule create    \
  --protocol tcp                                          \
  --direction inbound                                     \
  --priority 1000                                         \
  --destination-port-range 22                             \
  --access allow                                          \
  --resource-group $rgName                                \
  --nsg-name $nsgName                                     \
  --name allow-ssh

echo -e "=> Create allow-http rule"
docker exec -it azureCli azure network nsg rule create    \
  --protocol tcp                                          \
  --direction inbound                                     \
  --priority 1010                                         \
  --destination-port-range 80                             \
  --access allow                                          \
  --resource-group $rgName                                \
  --nsg-name $nsgName                                     \
  --name allow-http

echo -e "=> Create allow-docker-tls rule "
docker exec -it azureCli azure network nsg rule create    \
  --protocol tcp                                          \
  --direction inbound                                     \
  --priority 1020                                         \
  --destination-port-range 2376                           \
  --access allow                                          \
  --resource-group $rgName                                \
  --nsg-name $nsgName                                     \
  --name allow-docker-tls

echo -e "=> Create allow-jenkins-jnlp rule "
docker exec -it azureCli azure network nsg rule create    \
  --protocol tcp                                          \
  --direction inbound                                     \
  --priority 1030                                         \
  --destination-port-range 50000                          \
  --access allow                                          \
  --resource-group $rgName                                \
  --nsg-name $nsgName                                     \
  --name allow-jenkins-JNLP

## Added the two following rules further in the paper...
echo -e "=> Create allow-docker-registry rule"
docker exec -it azureCli azure network nsg rule create    \
  --protocol tcp                                          \
  --direction inbound                                     \
  --priority 1040                                         \
  --destination-port-range 5000                           \
  --access allow                                          \
  --resource-group $rgName                                \
  --nsg-name $nsgName                                     \
  --name allow-docker-registry

echo -e "=> Create allow-https rule"
docker exec -it azureCli azure network nsg rule create    \
  --protocol tcp                                          \
  --direction inbound                                     \
  --priority 1050                                         \
  --destination-port-range 443                            \
  --access allow                                          \
  --resource-group $rgName                                \
  --nsg-name $nsgName                                     \
  --name allow-https

echo -e "[info] Bind the NSG to the NIC"
docker exec -it azureCli azure network nic set            \
  --resource-group $rgName                                \
  --name $nicName                                         \
  --network-security-group-name $nsgName

## Added the registry blob storage later in this paper as well...
echo -e "[info] Create the Docker Registry Blob Storage"
docker exec -it azureCli azure storage account create     \
  --resource-group $rgName                                \
  --kind BlobStorage                                      \
  --sku-name LRS                                          \
  --access-tier Hot \
  --location $location
"${baseNameLower}${versionSuffix}registry"

echo -e "[info] Create the Virtual Machine"
docker exec -it azureCli azure vm create                  \
  --resource-group $rgName                                \
  --name $vmName                                          \
  --location $location                                    \
  --vm-size $vmSize                                       \
  --vnet-name $vnetName                                   \
  --vnet-address-prefix $vnetPrefix                       \
  --vnet-subnet-name $subnetName                          \
  --vnet-subnet-address-prefix $subnetPrefix              \
  --nic-name $nicName                                     \
  --os-type linux                                         \
  --image-urn "${publisher}:${offer}:${sku}:${version}"   \
  --storage-account-container-name vhds                   \
  --os-disk-vhd "${osDiskName}.vhd"                       \
  --admin-username $username                              \
  --ssh-publickey-file "/config/${rsaKeysLocation}/${adminKeyPairName}.pub"

## Removed because names need to be unique and this kept failing Azure assigns random name if omitted
##  --storage-account-name $stdStorageAccountName \

publicIPAddress=$(docker exec -it azureCli azure vm show $rgName $vmName |grep 'Public IP address' |awk -F':' '{print $3}' |tr -d '\r')

echo -e "[warn] PublicIP: ${publicIPAddress}"

echo -e "[info] Installing Docker Extension will fail unless we run an apt-get update in the VM"
ssh  -o StrictHostKeyChecking=no                  \
     -i "${rsaKeysLocation}/${adminKeyPairName}"  \
     "${username}@${fullDnsName}"                 \
     "sudo apt-get update"

printf "[info] Creating Docker TLS Certs"
mkdir -p "${tlsCertLocation}"
/bin/sh CreateDockerTLS.sh $customDnsName $fullDnsName $publicIPAddress $privateIPAddress $tlsCertLocation

echo -e "[info] Add Docker extension to Virtual Machine"
/bin/sh add-docker-ext.sh $rgName $vmName $tlsCertLocation

echo -ne " Finished!\n\n"

printf  "Connect to docker:\n"
printf  "cd ${tlsCertLocation}"
echo -e "[warn] RUN THIS:\n\ndocker\n --tlsverify\n --tlscacert=ca.pem\n --tlscert=cert.pem\n --tlskey=key.pem\n -H=tcp://${publicIPAddress}:2376\nversion"
