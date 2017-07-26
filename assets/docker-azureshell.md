## Docker in Azure via CLI


### Architectural Diagram

_Current:_

![Docker-Azure-Diagram](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/02-arch-docker-azure.png "Docker in Azure Diagram")


### Introduction

In this portion of my paper we will go one step further to script out the Azure CLI and TLS generation commands to (almost) automated the creation of the base of our Automated Build System. This is just another way to accomplish what we iterated over previously, so you are happy with using the Azure portal or manually running the CLI commands then you can skip this.


### The Scripts

The scripts can be found in this paper under the [bin/AutoBuildScripts](https://github.com/ehime/azure-containerpipeline/tree/master/bin/AutoBuildScripts). Lets start by cloning this repo.

```bash
$ git clone https://github.com/ehime/azure-containerpipeline.git AzurePipeline

$ mv AzurePipeline/bin/* .

$ cd AutoBuildScripts
```


### Customization

The main script is `AutoBuilcreate.sh`. Let’s take a look inside. We should first setup our naming conventions in the first 25 lines or so. The next ~50ish lines or so will be where we can optionally name the components of our installation and change things like your internal IP address and your vnet and subnet IP address range.


### The Azure CLI Docker Container

The first thing the script does is try to determine if the Azure CLI Docker container is running and if not, start it. If it is not around then it will try to run it `docker run -td --name azureCli -v "${SCRIPTS_LOCATION}:/config" microsoft/azure-cli` and map the current location to a volume in the container so we have access to config files, keys, and certificates. As of right now this code certainly isn’t foolproof but I’m looking to improve it over time and I welcome PRs and suggestions from the communitity.


### Creating SSH Keys

The default is to create the SSH keypair in `./keys/${NAME}` where name is the name of your system… so in our case that would be `dockerBuild`.
