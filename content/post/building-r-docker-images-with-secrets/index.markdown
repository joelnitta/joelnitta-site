---
title: Building R docker images with secrets
author: Joel Nitta
date: '2019-02-16'
slug: building-r-docker-images-with-secrets
summary: "Keep it secret. Keep it safe."
categories:
  - R
tags:
  - docker
  - reproducible research
header:
  caption: ''
  image: 'top_secret_header.png'
  preview_only: false
image:
  caption: ''
  focal_point: 'top'
  preview_only: true

---



Docker is an incredibly useful tool for running reproducible analysis workflows. For `useRs`, the [rocker](https://www.rocker-project.org/) collection of images is very convenient for creating version-controlled R environments. This is pretty straightforward if you are using packages on CRAN, or publicly available packages on GitHub. But what if we want to use private packages on GitHub, or need for any other reason to enter authentication credentials during the build?

There are various ways to copy data into the image during the build, but when handling secrets that we don't want hanging around after it's finished, caution is needed. Approaches such as using `COPY` or `ARGS` will leave traces in the build. Staged builds are more secure, but tricky. Fortunately, as of v. 18.09, Docker is now providing official support for handling secrets.

## A simple example

Here is how to use the new Docker features to securely pass a secret during a build ^[No guarantees!! This is just my understanding from reading the [docker documentation](https://docs.docker.com/develop/develop-images/build_enhancements/) and [other blogs](https://medium.com/@tonistiigi/build-secrets-and-ssh-forwarding-in-docker-18-09-ae8161d066)].

There are few non-default settings that need to be specified for this. First of all, prior to the `docker build` command, you need to specify that you want to use the new BuildKit backend with `DOCKER_BUILDKIT=1`. So the command starts `DOCKER_BUILDKIT=1 docker build ...`

Next, we must add a [syntax directive](https://docs.docker.com/engine/reference/builder/#syntax) to the top line of the `Dockerfile`. For example, for a `Dockerfile` based on `rocker/tidyverse`:

```shell
# syntax=docker/dockerfile:1.0.0-experimental
FROM rocker/tidyverse
```

Save your secrets in a text file. Let's call it `my_secret_stash`^[Of course, be sure to add the file containing the secret to `.gitignore`!]. If you are using it to store your [GitHub PAT](https://happygitwithr.com/github-pat.html), it would just be one line with the PAT. Here, let's put in some random word:

```shell
echo "FABULOUS" > my_secret_stash
```

This is all we need to use secrets during the build. Here is an example `Dockerfile` similar to the one in the [Docker documentation](https://docs.docker.com/develop/develop-images/build_enhancements/).

```shell
# syntax = docker/dockerfile:1.0-experimental
FROM alpine

RUN --mount=type=secret,id=mysecret cat /run/secrets/mysecret
```

To see how it works, save this as `Dockerfile`, then from the same directory containing `Dockerfile` and `my_secret_stash`, build the image:

```shell
DOCKER_BUILDKIT=1 docker build --progress=plain --no-cache --secret id=mysecret,src=my_secret_stash .
```

I've truncated the output, but at build step #7 you should see something like this.

<pre><output>
#7 [2/2] RUN --mount=type=secret,id=mysecret cat /run/secrets/mysecret
#7       digest: sha256:75601a522ebe80ada66dedd9dd86772ca932d30d7e1b11bba94c04aa55c237de
#7         name: "[2/2] RUN --mount=type=secret,id=mysecret cat /run/secrets/mysecret"
#7      started: 2019-02-18 20:51:20.1092144 +0000 UTC
#7 0.668 FABULOUS
#7    completed: 2019-02-18 20:51:21.0927656 +0000 UTC
#7     duration: 983.5512ms
</output></pre>

Can you spot our secret? It's showing up from the `cat` command. However, it will not remain in the image.

## Installing a private R package

To install a package from my private GitHub repo, I created an additional simple R script, called `install_git_packages.R`:

```r
secret <- commandArgs(trailing = TRUE)
devtools::install_github("joelnitta/my-private-package", auth_token = secret)
```

`commandArgs(trailing = TRUE)` will return whatever command line arguments were passed to `Rscript` after the name of the script, as a character vector.

We will call this script from the `Dockerfile` and pass the secret to it.

Here is the Dockerfile to do that. (Note that although we copy the `install_git_packages.R` script into the image, we are passing it the secret variable that is only present during the build, so this should not remain afterwards.)

```shell
# syntax = docker/dockerfile:1.0-experimental
FROM rocker/tidyverse:3.5.1

ENV DEBIAN_FRONTEND noninteractive

COPY install_git_packages.R .

RUN apt-get update

RUN --mount=type=secret,id=mysecret \
Rscript install_git_packages.R `cat /run/secrets/mysecret`
```

Let's build the image and tag it:
```shell
DOCKER_BUILDKIT=1 docker build --progress=plain --no-cache --secret id=mysecret,src=my_secret_stash . -t my_special_image
```

That's it!
