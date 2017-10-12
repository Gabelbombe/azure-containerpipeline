## Docker in Azure

### Architectural Diagram

_Current:_

![Jenkins-Ephemeral-Diagram](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/03-arc-jenkins-ephemeral.png "Jenkins in Ephemeral Diagram")


### Introduction

In this portion of the paper we will setup Jenkins in a Docker container, using a custom image and configure Jenkins to spin up slave build environments that are Docker containers, on demand and then remove them to clean up. Very cool stuff!


### The bootstrap code

My [Docker Jenkins](https://github.com/ehime/docker-jenkinsfiles) project out on github is what we’ll be using to bootstrap our system. It includes Dockerfile image definitions for all of the images we need to run our system. I’m not going to deep-dive into the Docker files in this tutorial but here’s a quick overview of the contents.

 - Jenkins Master is a custom Jenkins image that we will use as the backbone of our automated build system
 - Jenkins Data (for persistent data storage or our Jenkins settings)
 - NGINX for our web proxy
 - letsencrypt we will use to setup TLS/SSL on our system in part 3
 - Finally two sample ephemeral slave node images jenkins-slave and jenkins-dotnetcore-slave

Remember, in our final system software developers or more likely, development teams, will be responsible for creating their own build environment definitions but in order to make sure our system is functioning I’ve included these two starter examples.

SSH into our VM and clone the docker-jenkinsfiles repo:

```bash
ssh dockeruser@dockerbuild.ehimeprefecture.com

git clone https://github.com/ehime/docker-jenkinsfiles.git

Cloning into 'docker-jenkinsfiles'...
remote: Counting objects: 376, done.
remote: Total 376 (delta 0), reused 0 (delta 0), pack-reused 376
Receiving objects: 100% (376/376), 70.71 KiB | 0 bytes/s, done.
Resolving deltas: 100% (196/196), done.
Checking connectivity... done.

cd docker-jenkinsfiles
```

Then use docker-compose to build and startup our base containers

```bash
docker-compose -p jenkins up -d nginx data master

docker ps -a

shell showing results of docker ps -a
```

![Container-PS](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/03-containers-ps-a.png "Container PS")


Pop open a browser with an address (domain, IP address) that points to your VM (http://dockerbuild.ehimeprefecture.com for me) and you will see:

![Unlock-Jenkins](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/03-unlock-jenkins.png "Initial jenkins web view asking for initial password")

Our _custom_ Jenkins image is running in Docker on our VM in Azure. Great, but how do we get that initial password from the container?

The message tells us that the password can be found at `/var/jenkins_home/secrets/initialAdminPassword`. Makes sense - if we inspect the jenkins-master Dockerfile we see that `JENKINS_HOME` is mapped to `/var/jenkins_home`

![mapping-jenkins](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/03-dockerfile-jenkins-home.png "Image showing mapping of JENKINS_HOME to var jenkins home")

How do we get to that folder in the container? We can docker exec against the container - using the cat command to output the password to the console. Our container is jenkins-master_1:

```bash
docker exec jenkins_master_1 cat /var/jenkins_home/secrets/initialAdminPassword
```
![init-password](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/03-term-get-init-password.png "Terminal init for password")

Copy and paste that password into out web browser and click Continue


### Jenkins Initialization

Click on Install Suggested Plugins
![suggested-plugins](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/03-install-suggested-plugins.png "")

Think it’s a big enough button? Jenkins will proceed to install the suggested plugins
![plugins-install](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/03-plugins-installing.png "")

After the plugin install is complete, click Continue and create the initial admin user:
![create-admin](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/03-jenkins-create-first-admin.png "")

Click Save and Finish

Click Start Using Jenkins


### Jenkins TLS Certificate Credentials

So now we need to add those client certs to Jenkins so it can securely talk to our Docker host. Jenkins will be talking to our dockerhost to spin up and remove containers as needed so it need to be able to communicate securly with the host.

On the jenkins landing page click on "Credentials"

Then:

  1. Click "System"
  2. Click on "Add credentials"
  3. Click "Global credentials (unrestricted)"
  4. Click "Add Credentials"
  5. Select "Docker Host Certificate Authentication" in the "Kind" dropdown

We need to copy and paste the Client Key, Client Certificate and Server CA Certificate into the web interface. In Part 1 we created all of our certs in `~/tldBuild`. I’m going to use pbcopy to copy from the files onto my clipboard, one at a time and paste them into the web interface.

```bash
cd ~/tlsBuild
pbcopy < ~/tlsBuild/key.pem
pbcopy < ~/tlsBuild/cert.pem
pbcopy < ~/tlsBuild/ca.pem
```

  __NOTE:__ an earlier version of this post incorrectly had server-cert.pem in that last slot. It should be ca.pem. In Part 05 this will cause issues if not changed. (Updated 2017-08-23)

I’m going to add an ID of dockerTLS and a Description of Docker TLS Certs. This is what my final TLS credential screen looks like:
![jenkins-tls](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/03-jenkins-paste-tls.png "")

Click OK


### Add Cloud Config

Our custom Jenkins_Master Dockerfile automatically installs [Yet Another Docker Jenkins plugin](https://github.com/KostyaSha/yet-another-docker-plugin) which it what we will use to control our ephemeral slaves.

In jenkins-master Dockerfile:
<br/ >
![dockerfile-plugins](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/03-dockerfile-plugins.png "")


`Plugins.sh` is in the github repository (along with plugins.txt): If you want to auto-install Jenkins plugins add them to plugins.txt:
![dockerfile-plugins](https://raw.githubusercontent.com/ehime/azure-containerpipeline/master/assets/03-install-plugins.png "")
