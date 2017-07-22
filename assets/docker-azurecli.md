## Docker in Azure via CLI

### Architectural Diagram

_Current:_

![Docker-Azure-Diagram](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/02-arch-docker-azure.png "Docker in Azure Diagram")


### Introduction

In the previous portion we used the Azure Portal web interface to setup a Linux VM in Azure, installed Docker on that VM and setup secure communication to the remote Docker host. In this document we will do the same thing but through the Azure CLI ([Command-line Interface](https://en.wikipedia.org/wiki/Command-line_interface)). This is just another way to accomplish what we did prior too, so if you are happy with using the Azure portal then you can skip to the next section.
