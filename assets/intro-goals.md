### Introduction and Goals


##### Architectural Diagram

_Proposal:_

![Architectural-Diagram](https://github.com/ehime/azure-containerpipeline/blob/master/assets/01-architectural.png?raw=true "Architectural Diagram")


##### Introduction

Jenkins will be our CI/CD pipeline manager and it will spin up ephemeral slave nodes when needed. What I mean by that is Jenkins will spin up Docker containers as build environments that only get started when a build job needs them, so if you need a Java build environment or a .NET Core environment, Jenkins will start a Docker container to handle your build and then destroy that node/container when the build is complete.

We will also create a tool that I'm calling DockHand `(GoLang based)` that will allow developers (or dev teams) to submit their own build environments, as Docker images, into the system and create build jobs in Jenkins to use those images. This software engineers are responsible for their build environments not a (bottleneck) build engineering team. Very slick.

Anyway, I've been interested in containers for several years, but I have not had time to really dig in and understand Docker until recently. I watched Docker Deep Dive from Pluralsight, which really helped with my foundational knowledge. When I was searching for next steps, I found spatters of [LXC](https://en.wikipedia.org/wiki/LXC) technology blurbs but nothing concrete. So lots of experimentation and breaking things brought me to were I am today.


##### Story

  - As a build engineer I want to:
      - Avoid setting up environment after environment for dev teams
      - Concentrate on keeping the infrastructure healthy
      - Work to implement new features to streamline the process
  - As a software developer I want to:
      - Control my software through production without impediments
      - Have the freedom to create build envs without making special reqs


##### Outcome

  -  Dev creates a docker image for build environment
      - Engineer uses this locally to run, test and debug
  - Dev writes and tests code
      - Linting and unit testing can be married to Jenkins if req'd
      - Perf testing will not be inside this pipeline and be extraneous
  - Dev adds a text file to the repo that contains the Jenkins pipeline script
  - Dev pushes Docker image to the orgs private Docker registry
      - Registry should already be active
  - Dev uses a tool (CLI) to create the build job or CI/CD pipeline


So when you execute a command like the one below....

```bash
$ harbormaster --dockertlsfolder /tls/Certs                         \
                -registryuser     ehime                             \
                -registrypassword user1234!                         \
                -imagename        mage-hard                         \
                -label            mage_label                        \
                -jenkinsurl       https://bld.ehimeprefecture.com   \
                -jenkinsuser      bobTheBuilder                     \
                -jenkinspassword  bob1234!                          \
                -report           https://github.ehimeprefecture.com/user/mage-hard.git
```

All of this happens

  - Docker image of the build environment is pulled to Docker host
  - Docker container created and started
      - Test performed on Docker container
      - Actually runs and exits properly
      - Conforms to standards
  - Jenkins Docker Template is created
  - Jenkins Job is created

A complete CI/CD build pipeline/environment/process is created, no intervention by a build team or any other infrastructure team. Software development teams are responsible for everything (except, of course, maintaining the infrastructure that these process run on). Pretty cool, yeah?


##### Milestones

We will create this entire automated build system step-by-step (aka, our Milestones), from scratch, using Docker, Jenkins, Azure and GoLang. I'll even include a .NET Core as a sample app (since I should really brush the rust off...) just to mix things up.

  - Setup Docker in Azure (and connect securely from a remote machine)
  - Run Jenkins in Docker on the Azure
  - Setup Jenkins to spin up ephemeral (short-lived Docker containers) for Jenkins slaves
  - Setup a Docker registry/repository in Azure (including getting SSL certs)
  - Explore all the DockHand code (GoLang) to allow hands-off build job creation
  - Walk through creating a small sample software project utilizing this system
