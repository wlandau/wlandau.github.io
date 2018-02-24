---
layout: post
title: "A self-generating GitHub FAQ"
tags: 
  - R
---


```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE, eval = FALSE)
```

For a GitHub repository, the [issue tracker](https://help.github.com/articles/about-issues/) is a searchable online forum where the community can ask questions and discuss development. Issue trackers are great because they help make projects self-documenting. For even more convenience, we can scrape the issues to programmatically generate an FAQ.

1. [Label](https://help.github.com/articles/about-labels/) your favorite issues as frequently asked questions.
1. Scrape these FAQ issues from the tracker using [GitHub's REST API](https://developer.github.com/v3/).
1. Create a text of links to the FAQ issues.

Let's take my favorite project as an example: the <a href="https://github.com/ropensci/drake"><code>drake</code> R package</a>. Here, I flagged <a href="https://github.com/ropensci/drake/issues?q=is%3Aissue+is%3Aclosed+label%3A%22frequently+asked+question%22">several issues with the label, "frequently asked question"</a>, some open and some closed. I periodically run the R script, <a href="https://github.com/ropensci/drake/blob/master/docs.R">docs.R</a>, which generates an <a href="https://github.com/ropensci/drake/blob/master/vignettes/faq.Rmd">FAQ vignette</a>. With the <a href="https://github.com/r-lib/pkgdown"><code>pkgdown</code> package </a>, this vignette becomes an <a href="https://ropensci.github.io/drake/articles/faq.html">online index</a> to the original issues.

The FAQ-generating code uses the <a href="https://github.com/r-lib/gh"><code>gh</code> package</a>

<pre><code>library(tidyverse)
library(gh)
</code></pre>

and I define a couple supporting functions below. The tidyverse has more elegant solutions, but I am behind the curve.

<pre><code>
is_faq <- function(label){
  identical(label$name, "frequently asked question")
}

any_faq_label <- function(issue){
  any(vapply(issue$labels, is_faq, logical(1)))
}
</code></pre>

Next, I scrape the issue tracker to get a list of FAQ issues.

<pre><code>faq <- gh(
  "GET /repos/ropensci/drake/issues?state=all",
  .limit = Inf,
  .token = token
) %>%
  Filter(f = any_faq_label)
</code></pre>

I quickly hit my limit of <code>gh()</code> queries, so I followed <a href="https://gist.github.com/christopheranderton/8644743">this guide</a> to get a personal access token. Adding <code>Sys.setenv(GITHUB_TOKEN ="YOURAPITOKENWITHFUNKYNUMBERSHERE")</code> to my <code>.Rprofile</code> file solved the problem. (<code>"YOURAPITOKENWITHFUNKYNUMBERSHERE"</code> is not my actual token.)

Next, I created a text vector of links to the actual issues.

<pre><code>combine_fields <- function(lst, field){
  map_chr(lst, function(x){
    x[[field]]
  })
}
titles <- combine_fields(faq, "title")
urls <- combine_fields(faq, "html_url")
links <- paste0("- [", titles, "](", urls, ")")
</code></pre>

Finally, I moved <a href="https://github.com/ropensci/drake/blob/master/inst/stubs/faq.Rmd">this FAQ stub</a> to the <a href="https://github.com/ropensci/drake/tree/master/vignettes">vignettes folder</a> and appended the links.

<pre><code>starter <- system.file(
  file.path("stubs", "faq.Rmd"),
  package = "drake",
  mustWork = TRUE
)
dir <- rprojroot::find_root(criterion = "DESCRIPTION", path = getwd())
dest <- file.path(dir, "vignettes", "faq.Rmd")
tmp <- file.copy(
  from = starter,
  to = dest,
  overwrite = TRUE
)
con <- file(dest, "a")
writeLines(c("", links), con)
close(con)
</code></pre>

Because the FAQ is an R package vignette, <a href="https://github.com/r-lib/pkgdown"><code>pkgdown</code></a> automatically turns it into a <a href="https://ropensci.github.io/drake/articles/faq.html">webpage "article"</a>. Some <a href="">extra lines in <code>drake</code>'s <code>_pkgdown.yml</code> file</a> add "FAQ" to the navbar of the <a href="https://ropensci.github.io/drake/index.html">documentation website</a>.

This technique adds convenience and automation, but it is tough to set up from the beginning. I think I will nudge GitHub to support self-generating FAQs natively.