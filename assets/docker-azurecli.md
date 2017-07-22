## Docker in Azure via CLI

### Architectural Diagram

_Current:_

![Docker-Azure-Diagram](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/02-arch-docker-azure.png "Docker in Azure Diagram")


### Introduction

In the previous portion we used the Azure Portal web interface to setup a Linux VM in Azure, installed Docker on that VM and setup secure communication to the remote Docker host. In this document we will do the same thing but through the Azure CLI ([Command-line Interface](https://en.wikipedia.org/wiki/Command-line_interface)). This is just another way to accomplish what we did prior too, so if you are happy with using the Azure portal then you can skip to the next section.

### Azure CLI

You can [install the Azure CLI](https://azure.microsoft.com/en-us/documentation/articles/xplat-cli-install/) locally or if you run Docker on your machine (and I suspect you do if you are interested in this series) running the CLI in a Docker container is my favorite way to access the CLI - nothing installed on my machine!

It is as simple as:

```bash
$ docker run -it microsoft/azure-cli
```

### Create SSH Keys

First we are going to create a place for our public/private server and client certificates to live:

```bash
$ mkdir -p absSetup/{keys,certs} && \
  cd absSetup
```

And then generate our SSH keypair:

```bash
$ ssh-keygen                      \
 -t rsa                           \
 -b 2048                          \
 -C dockeruser@Azure-dockerBuild  \
 -f keys/id_dockerBuild_rsa       \
 -q                               \
 -N ''
```

Next we will startup the `azureCli` docker container linking our current directory to the `/config` folder in the container so we have access to the certs and keys.

```bash
docker run                                \
 -td                                      \
 --name azureCli                          \
 -v /Users/niigata/code/absSetup:/config  \
microsoft/azure-cli
```

From here on we will use `docker exec` to execute all of our Azure CLI commands in our running container.

We must login to the Azure CLI. This is nifty, similar to when you authorize a video device like an Xbox One with a provider such as Netflix.

```bash
$ docker exec -it azureCli azure login
```

After we follow the instructions we are logged in and we can procedd to use the Azure CLI. I have two Azure subscriptions, so I want to make sure I am using the correct one:

```bash
$ docker exec -it azureCli azure account set 'Visual Studio Enterprise'
```
