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
$mv AzurePipeline/bin/* .
$ cd AutoBuildScripts
```
