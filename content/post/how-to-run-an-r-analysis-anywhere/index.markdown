---
title: How to run an R analysis anywhere
author: Joel Nitta
date: '2018-11-06'
slug: how-to-run-an-r-analysis-anywhere
summary: 'What will *you* do when your laptop crashes?'
categories:
  - R
tags:
  - reproducible research
  - docker
  - git
header:
  caption: ''
  image: 'headers/how-to-run-an-r-analysis-anywhere.png'
  preview_only: false
image:
  caption: ''
  focal_point: 'top'
  preview_only: true
---
<!-- use a scroll box for wide output --> 
<!-- https://stackoverflow.com/questions/36845178/width-of-r-code-chunk-output-in-rmarkdown-files-knitr-ed-to-html --> 
<style>
pre {
  overflow-x: auto;
}
pre code {
  word-wrap: normal;
  white-space: pre;
}
</style>




I've been meaning to make all of my projects easily accessible on the cloud for a while now mostly for greater reproducibility. But other things (*ahem* actually writing code, *ahem ahem* labwork) have taken priority, so I never made everything fully cloud-deployable. Then I forgot my laptop charger at lab on a Friday before a three-day weekend. I now had much more motivation to achieve my goal. With a few hours' battery charge left, it was time to get my workflow on the cloud (then find someone's computer to borrow)! These are my notes for how to do so.[^1]

There are basically four components for running everything on the cloud: 

- a place to store code
- a place to store data
- a computing environment
- a server to run everything

There are various solutions to these problems, but I use, respectively: __github__, __google drive__, __docker__, and __digital ocean__.

## Launch an R container on digital ocean

[Digital Ocean](https://www.digitalocean.com) is cloud services platform. They do a lot of things, but the pertinent one for this post are their convenient [One-click Applications](https://www.digitalocean.com/docs/one-clicks/) that let you run servers ("droplets" in Digital Ocean parlance) for specific tasks very easily.

[Docker](https://www.docker.com/) is a freely-available system for running self-contained computing environments. It's great for reproducible research because it takes all the uncertainty out of the user's computer settings like software versions and dependencies. Even better, the [Rocker Project](https://www.rocker-project.org) maintains pre-built Docker images for R, so you don't have to worry about building it yourself (for R projects, anyways).

I use Digital Ocean's Docker application to run a Docker image on a server, which I can then access from a browser on any computer.

Here's how:

Create an account and login to Digital Ocean. Click the green __Create__ button in the upper right. Select __Droplets__, then under __Choose an Image__, click __One-click Apps__, then __Docker__. From here, you can choose how much juice you want your server to have and how much you want to pay for it. For typical R sessions, I've found the default $20 per month (3 cents per hr) server to be fine, or perhaps the next tier up. If most longish-running analyses take less than a day to a few days, this only costs you a few cups of coffee[^2].

Once the droplet is running, copy the IP address. In the terminal, run `ssh root@<IP address>`. Type the password provided in the email sent when the droplet got created (if you don't have an SSH key setup).

To launch one of the [Rocker R containers](https://www.rocker-project.org) (e.g., tidyverse), run

```console
docker run -d -p 8787:8787 -e USER=<user name> -e PASSWORD=<clever password> -e ROOT=true rocker/verse
```

Note that you need to provide `USER`, `PASSWORD`, and `ROOT`with the `-e` argument. Previous versions of Rocker containers would just allow you to sign in with login and password both "rstudio" by default, but no more.

Access the RStudio Server from your browser at `http://<IP ADDRESS>:8787`.

Login using the username and password you specified with the `docker run` command.

## Get your code

I'm going to assume ya'll know about git and github. If not, Jenny Bryan's [Happy Git with R](http://happygitwithr.com/) is a great place to start from an R-centric perspective, and there are loads of other resources out there.

RStudio Server gives us everything we need to edit and run R code from a browser window, but the working directory is still empty. We need to pull down our code from github. 

First though, let's create a new project in RStudio to house our code. This will allow us to access useful tools like the RStudio interface to git. 

Click __File__ &rightarrow; __New Project__ &rightarrow; __New Directory__ &rightarrow; __New Project__. Enter the name for your project and check the __Create a git repository__ box.

In the RStudio terminal window (the "terminal" tab is next to the "console" tab), add your remote repo with the canonical name "origin" for pulling code:

```console
git remote add origin https://github.com/<user>/<repo>.git
```

Pull your code (you may need to delete the existing `.gitignore` file first):

```console
git pull origin master
```

Tell git who you are:

```console
git config --global user.name "My Name"
git config --global user.email myname@somewhere.com
```

Now you should be able to edit code, save it, and push changes to your github repo.

## Get your data

The above steps may be all you need to run analyses and edit R code in RStudio on the cloud. However, my project also includes some large raw data files that are too big to host on github (and I wouldn't want to track raw data anyways). My solution to this is google drive and the `googledrive` [R package](https://googledrive.tidyverse.org/index.html).

You could either use usual google drive folders or a backup folder to host data, but I prefer the backup method. That way I don't have to move my raw data to a google drive folder, and I get an extra back-up to boot.

First, install [Backup and Sync](https://www.google.com/drive/download/backup-and-sync/).

Select the data folder you want to backup, and wait for everything to upload.

Install the `googledrive` R package:

```r
install.packages("googledrive")
```

The first time you use `googledrive`, it will ask you if you want to "use a local file ('.httr-oauth'), to cache OAuth access credentials between R sessions"? This is a very convenient way to securely access your google account, because the login info is stored in the `.httr-oauth` file, and you won't be tempted to save it in code or have to enter it manually every time. Be sure to add `.httr-oauth` to your `.gitignore`  to keep it out of your repo though.

You will need to find the path to your data folder on google drive. This may take some trial and error, depending on how your google drive is organized. The [`drive_ls()`](https://googledrive.tidyverse.org/reference/drive_ls.html) function is your friend here. The name of the folder I selected for back-up is `data_raw`, and its path on google drive is `My MacBook Pro/data_raw/`.

### Downloading files: simple case

If your backed-up data folder only consists of files within a single folder and no subdirectories, downloading it is simple.

Here I use the path to my `data_raw` folder on my google drive as an example. Create an empty `data_raw` folder within the RStudio project, then run:

```r
folder_contents <- drive_ls("My MacBook Pro/data_raw/")

purrr::walk2(
    map(folder_contents$id, as_id),
    paste0("data_raw/", folder_contents$name),
    drive_download,
    overwrite = TRUE
  )
```

### Downloading files: dealing with subfolders

If your data are organized into subfolders, things are a bit more tricky because `googledrive` only downloads files, not folders. Hopefully your organization scheme doesn't have too many subfolders, which make things hard to follow anyways. There is probably a way to recursively download everything and preserve the folder structure, but my work-around for now is to download files on a per-folder basis. 

I include a `README.MD` describing the files for each subfolder in `data` or `data_raw`, and track it with git (probably a good idea anyways). This way, my folder structure is preserved in the repo even though I ignore all the other raw data files.

I wrote [a function](https://gist.github.com/joelnitta/d38184c2554963d41587b910595ea081) based on the above code to filter out subfolders and download all the files in folder. I also put it in my lovely `jntools` [R package](https://github.com/joelnitta/jntools).

## Wrap-up

That's pretty much it. 

Be careful about downloading any results though, but because once the container is gone, anything inside it disappears for good!

[^1]: After writing the first draft of this post, my computer actually failed to start up after installing an update. I was able to run everything on a computer in my lab following my own instructions, so doing this was definitely worth it! 

[^2]: You are charged for the time the server exists, so make sure to destroy it when you're done or you will be billed even if it's just sitting there not running. Also, beware of weird error messages that may be the result of running out of memory if you were too cheap.
