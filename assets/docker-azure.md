## Docker in Azure

### Architectural Diagram

_Current:_

![Docker-Azure-Diagram](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/02-arch-docker-azure.png?token=AGLSaSwXnBWVaEx3i_r2uNrDtWR3EUOTks5ZSsAawA%3D%3D "Docker in Azure Diagram")


### Introduction

This section will cover setting up Docker in Azure on a Linux VM. There are several ways to accomplish this, but will only be covering a single solution. After we get this system up and running smoothly, we will explore another option for setting up the base system using the Azure command line interface (CLI). The architectural rough above will become the foundation for the pipeline and will be updated each section.


### Adding an Ubuntu VM to Azure

From the [Azure portal](http://portal.azure.com/). Click the New button in the left tray, search for Docker and several options appear; Docker on Ubuntu seems like the obvious choice since that is ultimately what we are trying to setup. Unfortunately it's not that simple, one problem is that only allows you to select the classic deployment model and also doesn't set up Docker for TLS and secure communication. Sure we can live with the classic model and we can configure secure Docker ourselves, but there is a better option.

Go back and search for Ubuntu and click the latest LTS release, currently 16.04.

Make sure the Deployment model is Resource Manager and click Create.

I am going to name this VM _dockerBuild_

One thing to note here is that you can save some money if you choose HDD - magnetic disks instead of solid state drives. Choosing HDD here opens up possibility so of cheaper plans which we will see in the next step.

Our admin user will be dockerUser and we are going to use SSH keys to authenticate and not username/password.


### Creating SSH keys

Open a terminal to create the public/private key pair. The C flag is just a comment - it's appended onto the end of the public key and it will serve as a reminder of what this keypair is for. We're not going to add a passphrase and we are going to name the files so that we have a clue as to what they are for ``~/.ssh/id_dockerbuild_rsa`.

```bash
$ ssh-keygen -t rsa -b 2048 -C "ehime@grr.la"

Generating public/private rsa key pair.
Enter file in which to save the key (/Users/niigata/.ssh/id_rsa): /Users/niigata/.ssh/id_dockerbuild_rsa
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /Users/niigata/.ssh/id_dockerbuild_rsa.
Your public key has been saved in /Users/niigata/.ssh/id_dockerbuild_rsa.pub.
The key fingerprint is:
SHA256:zy0VHseXTQUINXvEErBkmVHAFhvq0RBNdsrmTlWWkp8 ehime@grr.la
```

We need to add this identity to our ssh agent so that it is usable on our system. first we'll check to see if the ssh-agent is running, with eval...

```bash
$ eval "$(ssh-agent -s)" && \
  ssh-add ~/.ssh/id_dockerbuild_rsa
```

Finally we need to copy the public key to the clipboard. I'm on a Mac so I'm using "pbcopy" if you aren't you can open the key in a text editor or simply $ cat the contents to the terminal screen and copy from there.

```bash
$ pbcopy < ~/.ssh/id_dockerbuild_rsa.pub
```

Back in our browser, paste in the key. you can see our -C comment is here in the public key

We are going to create a new resource group and name it dockerBuild, I'm in Seattle so I'm chosing westus as the location.

![Azure-Basics](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/02-azure-basics.png?token=AGLSaZ64Ud8G3ylS-GoqRI5NhhTAhLCoks5ZSsC7wA%3D%3D "Azure Basics Menu")

Then, Click OK

### Pick Your Plan

Alright next we need to choose a plan for our VM. You will notice that even if you click View All we can't see the "A" plans that can be as cheap as $15 per month because I decided to leave the SSD selected. In preparing for this tutorial - I found that using the cheaper plans with the magnetic spinning disks made the Docker host run unbearably slow. So I'll pick the DS1_V2 Standard.

![Small-Plan](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/02-plan-small.png?token=AGLSacAzGm3dXxrlUMAbVecX-3YvCN1Lks5ZSsD8wA%3D%3D "Azure Pick Small Plan")

Click Select

### More VM Settings

I am leaving all of the default names here for the storage account and all of the networking components. Over the past couple years of working with resources in the cloud, I've found that I don't care about machine / resource names. I used to plan out resource names, even going with themes like Lord of the Rings or Star Wars. Well now all of the resources are disposable and easily destroyed and rebuilt so names just don't matter to me any more. I'm not going to setup a high availability set either. So I am going with all of the defaults. Click okay.

![VM-Settings](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/02-vm-settings.png?token=AGLSaVlhYKRnATMfcwszJ-w3EZ2dIEonks5ZSsEIwA%3D%3D "Azure VM Settings")

Azure validates the build, give us a quick summary. Click okay one more time and Azure starts provisioning the VM for us.

### VM Preparation

Once Azure has completed it's work, back to the Azure portal. Click on Resource Groups.

Click on dockerBuild (Resource Group), this gives us a view of our newly provisioned VM and supporting cast including all of the networking and storage components.

Click on dockerBuild (the VM). Then click on the IP address.

Add a DNS name to our IP settings… Click Configuration - I will use dockerbuildsys

We want to take note of the public IP address and DNS name for our VM... so I'll open a text editor, Visual Studio Code is my current favorite, to take a few notes.

Click Save

Copy the DNS and IP, paste them in a text editor.

I will also point a custom DNS name at this VM. Later in this series we’re going to get TLS certificates from [letsencrypt](https://letsencrypt.org/) for secure https communication to our private Docker registry. We will must have a custom domain name to make that happen. The quick reason is that Azure domains are secured by wildcard certs which won’t work for our purposes. _If you don’t have a domain name I strongly suggest that you obtain one so that we can establish secure communication with our private Docker Registry (and Jenkins)._

All name providers are different and you can google for how to add an a-record at yours. At my provider in the Host Records interface I will just paste the public IP address into the A-record for the domain name I want to use __dockerbuild.ehimeprefecture.com__.

![Host-Record](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/02-host-record.png?token=AGLSaVlhYKRnATMfcwszJ-w3EZ2dIEonks5ZSsEIwA%3D%3D "Host a Record")

Here are my notes so far:

  - 40.78.31.164
  - dockerbuild.ehimeprefecture.com
  - dockerbuildsys.westus.cloudapp.azure.com

We will be adding our local IP address to this list shortly.
