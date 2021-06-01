---
title: A new color scheme for mapping ancestral states
author: Joel Nitta
date: '2021-06-01'
slug: new-color-scheme-anc-states
categories:
  - R
tags:
  - R
subtitle: ''
summary: 'How to change the phytools default color scheme when visualizing the results of ancestral character state estimation'
authors: []
lastmod: '2021-06-01T17:36:13+09:00'
featured: no
image:
  caption: ''
  focal_point: ''
  preview_only: no
projects: []
---




The `phytools` package provides (among many other things) the `contMap()` function for estimating ancestral character states and [visualizing their changes along the branches of a phylogenetic tree](http://blog.phytools.org/search?q=contmap). It can either produce the plot directly (default), or be saved as an object with the `plot = FALSE` argument, to be further manipulated and plotted later with `plot()`.

However, I have to say I'm not a fan of the default color scheme, which is a rainbow palette going from red through yellow and green to blue. 

For example, let's borrow some example code and look at the default plot:


```r
# Example plotting ancestral state character reconstruction
# from phytools with color palettle from scico

# modified slightly from http://www.phytools.org/eqg2015/asr.html

## Load needed packages for this blogpost
library(phytools)
library(ggtree)
library(tidyverse)
library(scico)

## Load anole tree
anole.tree <- read.tree("http://www.phytools.org/eqg2015/data/anole.tre")

## Load anole trait data, extract snout-vent-length (svl) as named vector
svl <- read_csv("http://www.phytools.org/eqg2015/data/svl.csv") %>%
  mutate(svl = set_names(svl, species)) %>%
  pull(svl)

# Default plot: projection of the reconstruction onto the edges of the tree
obj <- contMap(anole.tree, svl, plot = FALSE)
plot(obj,type="fan",legend=0.7*max(nodeHeights(anole.tree)),
     fsize=c(0.7,0.9))
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/plot-contmap-default-1.png" width="672" />

Although this does provide a wide range of colors, it's not obvious why one color is greater or less than the others without constantly looking at the legend. In particular it's hard to discern the order of intermediate values. Indeed, there has been much written on [why the rainbow palette is generally not a good way to visualize continuous data](https://www.nature.com/articles/s41467-020-19160-7).

There is a `phytools` function available to manipulate the color palette, `setMap()`. However, `setMap()` just passes its input (a vector of color names or hexadecimals) to `colorRampPalette()`. So if we wanted to use any of the nice color palettes available in say the [`scico`](https://github.com/thomasp85/scico) package, those wouldn't be available.

One way to get around this is to use [`ggtree`](https://github.com/YuLab-SMU/ggtree), which uses `ggplot2` for plotting. Then we can provide palettes from `scico` or other similar packages as color scales.


```r
# Modified from https://yulab-smu.top/treedata-book/chapter4.html#color-tree

# Fit an ancestral state character reconstruction
fit <- phytools::fastAnc(anole.tree, svl, vars = TRUE, CI = TRUE)

# Make a dataframe with trait values at the tips
td <- data.frame(
  node = nodeid(anole.tree, names(svl)),
  trait = svl)

# Make a dataframe with estimated trait values at the nodes
nd <- data.frame(node = names(fit$ace), trait = fit$ace)

# Combine these with the tree data for plotting with ggtree
d <- rbind(td, nd)
d$node <- as.numeric(d$node)
tree <- full_join(anole.tree, d, by = 'node')

ggtree(
  tree, 
  aes(color=trait), 
  layout = 'circular', 
  ladderize = FALSE, continuous = "color", size=2) +
  # >>> The important part! <<<
  # Choose your favorite scale_color_* function here: 
  scale_color_scico(palette = "bilbao") + 
  geom_tiplab(hjust = -.1) + 
  xlim(0, 1.2) + 
  theme(legend.position = c(.05, .85)) 
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/plot-contmap-ggtree-1.png" width="672" />

I find the values on the second plot are much easier to interpret.


```r
sessionInfo()
```

```
## R version 4.1.0 (2021-05-18)
## Platform: x86_64-apple-darwin17.0 (64-bit)
## Running under: macOS Catalina 10.15.7
## 
## Matrix products: default
## BLAS:   /Library/Frameworks/R.framework/Versions/4.1/Resources/lib/libRblas.dylib
## LAPACK: /Library/Frameworks/R.framework/Versions/4.1/Resources/lib/libRlapack.dylib
## 
## locale:
## [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
## 
## attached base packages:
## [1] stats     graphics  grDevices datasets  utils     methods   base     
## 
## other attached packages:
##  [1] scico_1.2.0     forcats_0.5.1   stringr_1.4.0   dplyr_1.0.6    
##  [5] purrr_0.3.4     readr_1.4.0     tidyr_1.1.3     tibble_3.1.2   
##  [9] ggplot2_3.3.3   tidyverse_1.3.1 ggtree_3.0.1    phytools_0.7-70
## [13] maps_3.3.0      ape_5.5        
## 
## loaded via a namespace (and not attached):
##  [1] nlme_3.1-152            fs_1.5.0                lubridate_1.7.10       
##  [4] httr_1.4.2              numDeriv_2016.8-1.1     tools_4.1.0            
##  [7] backports_1.2.1         utf8_1.2.1              R6_2.5.0               
## [10] DBI_1.1.1               lazyeval_0.2.2          colorspace_2.0-1       
## [13] withr_2.4.2             tidyselect_1.1.1        mnormt_2.0.2           
## [16] phangorn_2.7.0          curl_4.3.1              compiler_4.1.0         
## [19] cli_2.5.0               rvest_1.0.0             expm_0.999-6           
## [22] xml2_1.3.2              labeling_0.4.2          bookdown_0.21          
## [25] scales_1.1.1            quadprog_1.5-8          digest_0.6.27          
## [28] rmarkdown_2.6           pkgconfig_2.0.3         htmltools_0.5.1.1      
## [31] plotrix_3.8-1           dbplyr_2.1.1            rlang_0.4.10           
## [34] readxl_1.3.1            rstudioapi_0.13         farver_2.1.0           
## [37] generics_0.1.0          combinat_0.0-8          jsonlite_1.7.2         
## [40] gtools_3.8.2            magrittr_2.0.1          patchwork_1.1.1        
## [43] Matrix_1.3-3            Rcpp_1.0.5              munsell_0.5.0          
## [46] fansi_0.5.0             lifecycle_1.0.0         scatterplot3d_0.3-41   
## [49] stringi_1.5.3           yaml_2.2.1              clusterGeneration_1.3.7
## [52] MASS_7.3-54             grid_4.1.0              parallel_4.1.0         
## [55] crayon_1.4.1            lattice_0.20-44         haven_2.4.1            
## [58] hms_1.1.0               tmvnsim_1.0-2           knitr_1.30             
## [61] pillar_1.6.1            igraph_1.2.6            codetools_0.2-18       
## [64] fastmatch_1.1-0         reprex_2.0.0            glue_1.4.2             
## [67] evaluate_0.14           blogdown_0.21.71        renv_0.12.0            
## [70] BiocManager_1.30.15     modelr_0.1.8            vctrs_0.3.8            
## [73] treeio_1.17.0           cellranger_1.1.0        gtable_0.3.0           
## [76] assertthat_0.2.1        xfun_0.19               broom_0.7.6            
## [79] tidytree_0.3.4          coda_0.19-4             aplot_0.0.6            
## [82] rvcheck_0.1.8           ellipsis_0.3.2
```

