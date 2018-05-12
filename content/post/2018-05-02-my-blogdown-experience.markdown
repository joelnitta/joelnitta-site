---
title: Thoughts on blogdown
author: Joel Nitta
date: '2018-05-02'
slug: my-blogdown-experience
categories:
  - R
tags:
  - R
  - blogdown
header:
  caption: ''
  image: ''
output:
  blogdown::html_page
---

I recently decided to completely overhaul my personal website using [blogdown](https://bookdown.org/yihui/blogdown/). There are already some great [posts](#resources) on this topic, so I won't go into too much detail. Rather, I will just provide a quick overview of the process, and some thoughts on what worked well and where I had difficulty.

## Blogdown

Strictly speaking, `blogdown` is an [R package](https://github.com/rstudio/blogdown) that allows one to write blogposts using R markdown, but the [book](https://bookdown.org/yihui/blogdown/) covers much more than just this -- it explains how completely (and relatively easily) set up a website centered around such a blog. My current site is one such example. I can weave R code into my posts, edit everything locally, and when I'm ready to update I just `git push` my changes to the server. Sweet.

## Workflow summary

The steps to set up a site can be grouped into two major sections: making the webpage on your computer, and deploying the webpage to a server. Again, I'm not going into details since so many other blog posts and the book cover those, but this is just a quick overview so you can see how the process works.

### Make the webpage locally

1. Install RStudio and the necessary R packages.
2. Your website will be managed as an R project. To make a new R project, in RStudio, select File -> New Project -> New Directory (or exisiting directory if you prefer) -> Website using blogdown.
3. In the next menu, choose a theme and whether you want to start with the example webpage files or not. Include the example files to see what a functioning webpage looks like. (These two steps can also be accomplished using `blogdown::new_site()`).
4.Edit the webpage locally to your liking. Use `blogdown::serve_site()` to see how changes to your code appear on your webpage.

### Deploy the webpage to a server

There are several ways to do this, but by far the easiest is with [Netlify](https://www.netlify.com/). If you aren't concerned about using `git push` to update your website, all you have to do is:

1. Create an account on [Netlify](https://www.netlify.com/) by logging in with your github credentials.
2. Upload your pre-built webpage to your account by dragging the `public/` folder onto your Netlify account page. Done. 

You will have a URL with some randomly-generated words that is less than ideal, but there are [various ways](https://bookdown.org/yihui/blogdown/domain-name.html#domain-name) to change this.

## Points of caution

These are some things that I noticed that aren't mentioned in some of the other blogs or the book.

### Watch for silent build errors

Although `blogdown::serve_site()` is awesome in the respect that it automatically refreshes the site on each save, doesn't do any error checking to make sure that Hugo compiled correctly. Instead, it simply won't refresh. So it is very easy to miss an error that actually broke your site. I hope that in future versions `blogdown` takes this into account and throws some sort of error message. For now, I think the best thing to do is `git commit` whenever you make a change and are sure that the site is compiling correctly. This way can easily revert if you break something several saves later without noticing. If you suspect something fishy, navigate to the root directory of your site, and in the terminal run `hugo -v`. This is the command for hugo to build your site and be verbose about the output. If it gives you an error message, that can be useful for diagnosing the cause of the problem.

### Don't be a (inadvertent) copycat
If you use the popular [Academic](https://github.com/gcushen/hugo-academic) theme, please be sure to delete the default blog post! I don't know how many times I saw this and thought everyone was writing about the exact same thing.

## Resources

`blogdown` already seems quite popular, and there are number of excellent resources out there to guide you to getting setup, in addition to the [book](https://bookdown.org/yihui/blogdown/). Here are some I found useful.

* Dan Quintana's [tweetorial](https://twitter.com/dsquintana/status/993410504570888192) provides an excellent and quick overview!

<!--html_preserve-->{{% tweet "993410504570888192" %}}<!--/html_preserve-->

* Mikey Harper's [post](https://mikeyharper.uk/migrating-to-blogdown/) on the benefits of `blogdown`.

* Alison Presmanes Hill's [tutorial](https://alison.rbind.io/post/up-and-running-with-blogdown/) goes into much more detail.

* Emi Tanaka's [post](https://emitanaka.github.io/post/blogdowntutorial/) on adding some "bling" to your `blogdown` site.

* George Cushen's [guide](https://sourcethemes.com/academic/docs/) to using the Academic theme.
