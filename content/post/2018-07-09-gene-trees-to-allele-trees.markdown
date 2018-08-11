---
title: Gene trees to allele trees
author: Joel Nitta
date: '2018-07-09'
slug: gene-trees-to-allele-trees
summary: Making species complexes a *little* bit easier to understand
categories: [R]
tags: [R]
header:
  caption: ''
  image: ''
draft: TRUE
---

Interpreting phylogenetic trees is fairly straightforward when there is a one-to-one relationship between the tips of the tree and the source of the sequences. This is typically the case for datasets where the sequences are from chloroplast or mitochondrial genes, so there is only a single copy per individual. 

However, things aren't so neat when you're dealing with nuclear genes of polyploids and hybrids (as often occur in ferns)! These may harbor multiple sequence copies in each individual, and may share identical copies across different individuals. In such cases, a "normal" phylogenetic tree (what I'll call the "gene tree") can be downright confusing. It can be easier to instead identify all the unique sequences in the alignment (here, I'll call these "alleles"), and infer a tree of these alleles (the "allele tree"). We would then look at this in tandem with a table showing which individual possesses which allele(s). 

I recently came across just this case in my research, but I wasn't aware of any script to automate going from gene trees to allele trees. Doing this sort of thing by hand is tempting fate and awkward to do everytime we get new data, so I wrote an R script to do it. Let's see how!

First, generate some toy data using `phytools`.


```r
library(phytools)

# For reproducibility
set.seed(123)

# Simulate a tree with 10 species and some DNA sequence data
phy <- pbtree(n=10, tip.label=paste0("Sp_", LETTERS[1:10]))
gg <- rgamma(n=100, shape=0.25, rate=0.25)
alignment <- genSeq(phy, l=100, rate=gg)
```

Let's have a look at our simulated data. This is what a "normal" tree might look like:


```r
# Make the tree prettier for plotting
phy <- ladderize(phy, right = FALSE)

# View the tree
plot (phy)
```

<img src="/post/2018-07-09-gene-trees-to-allele-trees_files/figure-html/view_basic_data-1.png" width="672" />

Now we'll tweak the dataset a bit to reflect what a polyploid dataset might look like


```r
# First let's add 5 more "species" to the alignment
more_species <- alignment[sample(nrow(alignment), 5, replace = TRUE), ]
rownames(more_species) <- paste0("Sp_", LETTERS[11:15])
alignment <- rbind(alignment, more_species)

# Randomly resample some of the alignment and scramble the names
more_data <- alignment[sample(nrow(alignment), 10), ]
rownames(more_data) <- sample(rownames(more_data), 10)

# Now each species can have multiple sequences.
# We'll call these "seq_1" and "seq_2"
rownames(alignment) <- paste0(rownames(alignment), "_seq_1")
rownames(more_data) <- paste0(rownames(more_data), "_seq_2")

# Combine the two datasets
alignment <- rbind(alignment, more_data)

# Make a quick neighbor-joining tree
phy <- nj(dist.dna(alignment))

# Ladderize and view the tree
phy <- ladderize(phy, right = FALSE)
plot (phy)
```

<img src="/post/2018-07-09-gene-trees-to-allele-trees_files/figure-html/make_polyploid_data-1.png" width="672" />

Ugh. See what I mean? Deducing which species have multiple alleles and where they are on the tree requires a lot of squinting. Let's work on making this an "haplotype tree".

Start by identifying groups of identical sequences and collapsing them into haplotypes. Note that the use of `seqinr::consensus` is redudant here since sequences separated by distance of zero in our toy data are identical. However, this is not the case in real-life, when zero-distance sequences may actually differ by insertion/deletion mutations (indels) or sequence length.


```r
library(seqinr)
```

```
## 
## Attaching package: 'seqinr'
```

```
## The following objects are masked from 'package:ape':
## 
##     as.alignment, consensus
```

```r
library(tidyverse)
```

```
## ── Attaching packages ──────────────────────────────────────────────────── tidyverse 1.2.1 ──
```

```
## ✔ ggplot2 3.0.0     ✔ purrr   0.2.5
## ✔ tibble  1.4.2     ✔ dplyr   0.7.6
## ✔ tidyr   0.8.1     ✔ stringr 1.3.1
## ✔ readr   1.1.1     ✔ forcats 0.3.0
```

```
## Warning: package 'dplyr' was built under R version 3.5.1
```

```
## ── Conflicts ─────────────────────────────────────────────────────── tidyverse_conflicts() ──
## ✖ dplyr::count()  masks seqinr::count()
## ✖ dplyr::filter() masks stats::filter()
## ✖ dplyr::lag()    masks stats::lag()
## ✖ purrr::map()    masks maps::map()
```

```r
map <- purrr::map

# Calculate distances (note confusing pairwise deletion
# setting - if set to FALSE, it *does* delete all gaps)
distances <- dist.dna(alignment, pairwise.deletion = TRUE, 
                      model="raw", as.matrix=FALSE)
  
# Get groups of identical sequences
# (those with zero distance separating theme)
haplotype_groups <- cutree(hclust(distances), h=0)
  
# Split alignment up by these groups
split_alignments <- split(alignment, haplotype_groups)
  
# Calculate consensus of each alignment; 
# these are the haplotypes
haplotypes <- map(split_alignments, ~ 
                   seqinr::consensus(
                     as.character(as.matrix(.x)), 
                     method = "majority"))
  
# Convert list of haplotypes back into DNA alignment
#haplotypes <- dplyr::bind_rows(haplotypes)
#haplotypes <- t(haplotypes)
#haplotypes <- as.DNAbin(haplotypes)
```



```r
library(pegas)
```

```
## Loading required package: adegenet
```

```
## Loading required package: ade4
```

```
## 
##    /// adegenet 2.1.1 is loaded ////////////
## 
##    > overview: '?adegenet'
##    > tutorials/doc/questions: 'adegenetWeb()' 
##    > bug reports/feature requests: adegenetIssues()
```

```
## 
## Attaching package: 'pegas'
```

```
## The following object is masked from 'package:ade4':
## 
##     amova
```

```
## The following object is masked from 'package:ape':
## 
##     mst
```

```r
library(tidyverse)

haplotype(alignment)
```

```
## 
## Haplotypes extracted from: alignment 
## 
##     Number of haplotypes: 10 
##          Sequence length: 100 
## 
## Haplotype labels and frequencies:
## 
##    I   II  III   IV    V   VI  VII VIII   IX    X 
##    2    2    3    3    2    2    3    2    4    2
```

Note that `pegas::haplotype` does something very similar. However, it's not clear to me how it handles missing data. By using `ape::dist.dna` and `seqinr::consensus` above, we have more control over how to call haplotypes.

