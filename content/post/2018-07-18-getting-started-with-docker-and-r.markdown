---
title: Getting started with Docker and R
author: Joel Nitta
date: '2018-07-18'
slug: getting-started-with-docker-and-r
categories:
  - R
tags:
  - docker
header:
  caption: ''
  image: ''
draft: TRUE
---

I've been meaning to step up my reproducibility game by using docker for a while, and finally got around to learning it recently. This post is notes from that experience that I hope will be helpful to others.

## Motivation

The main reason for doing this is the usual one: so others can reproduce my analyses! However, there are various layers to reproducibility. Just using R (or any other language) and scripts is a huge improvement over interactive analysis. However, the _environment_ in which the scripts are run also has a huge impact. I've recently been trying to share some of my scrips with collaborators, and get completely unexpected errors because we are running them on different computers. _docker_ gets around this by providing images, similar to virtual machines.

## Adding to the PATH

For my current project, I rely heavily on various programs that I call from R using `system()` and its friends `system2()` and the excellent `processx` package. However, I noticed something distressing: the exact same call at the command line wasn't working from within R:

```
joel-nittas-macbook-pro:~ joelnitta$ docker run -it --rm baitfindr bash
root@ec406d10ec20:/# blastn -version
blastn: 2.6.0+
 Package: blast 2.6.0, build Dec  7 2016 14:50:34
 
root@ec406d10ec20:/# Rscript -e 'system("blastn -version")'
sh: 1: blastn: not found
Warning message:
In system("blastn -version") : error in running command
```

This is because the PATH variable is different between linux and R. This is made clear by running the following:

```
root@ec406d10ec20:/# echo $PATH
.:/ncbi-blast-2.6.0+/bin:.:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/usr/lib/rstudio-server/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

root@ec406d10ec20:/# Rscript -e 'system("echo $PATH")'
/usr/lib/rstudio-server/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

We need to add the new paths to R's PATH variable by adding an `.Renviron` file. Based on reading other blog posts, I thought this had to be done from R's "home directory" (the output of `R RHOME`), but it apparently needs to be placed in the working directory you call R from.

This is an example of what put in your `.Renviron` file to fix PATH, e.g., to add the path to BLAST. Note that the file must be named _exactly_ as `.Renviron`, including the `.` at the front!

```
PATH=/ncbi-blast-2.6.0+/bin:${PATH}
```
