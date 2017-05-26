# Automated Azure Container Pipeline

### Introduction and Goals

##### Introduction

In this scenario we will create an entire Automated Build System (ABS) step-by-step, from scratch, using Docker, Jenkins, Azure, and PHP (Magento).

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
