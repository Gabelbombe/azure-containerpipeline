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

Add a DNS name to our IP settings... Click Configuration - I will use dockerbuildsys

We want to take note of the public IP address and DNS name for our VM... so I'll open a text editor, Visual Studio Code is my current favorite, to take a few notes.

Click Save

Copy the DNS and IP, paste them in a text editor.

I will also point a custom DNS name at this VM. Later in this series we're going to get TLS certificates from [letsencrypt](https://letsencrypt.org/) for secure https communication to our private Docker registry. We will must have a custom domain name to make that happen. The quick reason is that Azure domains are secured by wildcard certs which won't work for our purposes. _If you don't have a domain name I strongly suggest that you obtain one so that we can establish secure communication with our private Docker Registry (and Jenkins)._

All name providers are different and you can google for how to add an a-record at yours. At my provider in the Host Records interface I will just paste the public IP address into the A-record for the domain name I want to use __dockerbuild.ehimeprefecture.com__.

![Host-Record](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/02-host-record.png?token=AGLSaQ8kBzQLsTvUweze0GCRSvXS-AoRks5ZSsLjwA%3D%3D "Host a Record")

Here are my notes so far:

  - 40.78.31.164
  - dockerbuild.ehimeprefecture.com
  - dockerbuildsys.westus.cloudapp.azure.com

We will be adding our local IP address to this list shortly.

### SSH to our VM

Azure already opened up port 22 for SSH communication, very thoughtful of Microsoft.

Connect via SSH - we'll use our custom domain name.

```bash

$ ssh dockeruser@dockerbuild.ehimeprefecture.com

Welcome to Ubuntu 16.04.1 LTS (GNU/Linux 4.4.0-38-generic x86_64)
...
To run a command as administrator (user "root"), use "sudo <command>".

dockeruser@dockerBuild:~$
```

Connected! While we are in here we're going to grab the local/private IP address using the ifconfig command:

```bash
$ ifconfig

eth0      Link encap:Ethernet  HWaddr 00:0d:3a:30:21:a5
          inet addr:10.0.0.4  Bcast:10.0.0.255  Mask:255.255.255.0
          inet6 addr: fe80::20d:3aff:fe30:21a5/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:1674984 errors:0 dropped:2 overruns:0 frame:0
          TX packets:567214 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:2252753926 (2.2 GB)  TX bytes:238825364 (238.8 MB)
```

We want the inet addr for the `eth0 adapter`. We'll also copy that into our notes for use later. We can exit / logout of the SSH session.

```bash
$ exit

logout
Connection to dockerbuild.ehimeprefecture.com closed.
$
```

Back into the Azure portal – we need to open a few more ports for our system to work.

Click on `dockerBuild (Resource Group) > Network Security Group, [Inbound Security Rules]`, then click add.

The first rule we are going to add is for web/http access for our Jenkins server. HTTP is a preconfigured service you can pick from the Services drop-down. Lets name this allow-http, click ok.

Next we're going to add secure web / https communication. Select HTTPS from the Service drop down. We'll call this `allow-https`, click ok.

Last one we are going to add for now, we are going open a port for secure Docker TLS communication. We'll call this allow-docker-tls and since this is not a preconfigured service so we have to make a couple more choices:

  - TCP as the protocol
  - Port 2376

Click OK

Our inbound security rules should now look about like this:

![Ingress-Rules](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/02-ingress-rules.png?token=AGLSaU2YqOaLJDyG20Lw9Dk-AyFJz7bmks5ZSsR7wA%3D%3D "Inbound (ingress) Rules")

### TLS CA and Certs

We have one more thing to do before we install Docker in our VM. Docker uses [TLS](https://en.wikipedia.org/wiki/Transport_Layer_Security) with client certificates for authentication to communicate with remote hosts. Our Docker host daemon will only accept connections from clients authenticated by a certificate signed by that CA. So we will create our own certificate authority, server and client certs and keys. Interesting aside regarding self-signed client certs: [Trusted CA for Client Certs](https://schnouki.net/posts/2015/11/25/lets-encrypt-and-client-certificates/)?

For the sake of organization we are going to create a local folder to hold our CA and certs.

```bash
$ mkdir -p tlsBuild && cd $_
```

First we will create the certificate authority key and we must add a passphrase

```bash
$ openssl genrsa -aes256 -out ca-key.pem 4096

Generating RSA private key, 4096 bit long modulus
..........................................++
...........++
e is 65537 (0x10001)
Enter pass phrase for ca-key.pem:
Verifying - Enter pass phrase for ca-key.pem:
```

Next we will create the certificate authority itself...

```bash
$ openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem

Enter pass phrase for ca-key.pem:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) []:US
State or Province Name (full name) []:Washington
Locality Name (eg, city) []:Seattle
Organization Name (eg, company) []:Ehime Prefecture, LLC
Organizational Unit Name (eg, section) []:Cloud Infrastructure
Common Name (e.g. server FQDN or YOUR name) [Jd Daniel]:ehimeprefecture.com
Email Address []:niigata@ehimeprefecture.com
```

Now that we have a certificate authority, we can create a server key and certificate signing request (CSR) and with these we will create our server certificate. Make sure that “Common Name” or CN matches the hostname you will use to connect to Docker in my case that is my custom domain name.

```bash
$ openssl genrsa -out server-key.pem 4096

$ openssl req -subj "/CN=dockerbuild.ehimeprefecture.com" -sha256 -new -key server-key.pem -out server.csr
```

Since the TLS connection can be made via IP address (between machines on the private network in Azure, `localhost:127.0.0.1`, and to the public IP address from external machines) in addition to two DNS names, we need to specify all of the DNS and IP options. This is done in a certificate extensions file. We will just echo the options out to that file...


echo subjectAltName = IP:40.78.31.164,IP:10.0.0.4,IP:127.0.0.1,DNS:dockerbuildsys.westus.cloudapp.azure.com,DNS:dockerbuild.ehimeprefecture.com > extfile.cnf

Finally we will actually create the server certificate

```bash
$ openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf
```

Server side done. Now for client authentication we will create a client key and certificate signing request which we will use to create our client cert

```bash
$ openssl genrsa -out key.pem 4096

$ openssl req -subj '/CN=client' -new -key key.pem -out client.csr
```

To make the certificate suitable for client authentication, update our certificate extensions

```bash
$ echo extendedKeyUsage = clientAuth > extfile.cnf

$ openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile.cnf
```

After generating our client and server certificates, cert.pem and server-cert.pem, we can safely remove the two certificate signing requests.

```bash
$ rm -v client.csr server.csr
```

In order to protect your keys from accidental damage, you will want to remove write permissions and also make them only readable by you, change file modes as follows:

```bash
$ chmod -v 0400 ca-key.pem key.pem server-key.pem
```

Certificates can be world-readable, but you might want to remove write access to prevent accidental damage:

```bash
$ chmod -v 0444 ca.pem server-cert.pem cert.pem
```

I guess this is as good of a time as any to bring this up… anyone with these keys can give any instructions to your Docker daemon, including giving them root access to the machine hosting the daemon. Guard these keys as you would a root password!
