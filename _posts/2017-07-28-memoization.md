---
layout: post
title: "The strengths and perils of traditional memoization"
---

## Efficiency gains

<p>
<a href="https://en.wikipedia.org/wiki/Memoization">Memoization</a> is the practice of storing the return values of function calls for later use. A memoized function simply reads a previous result if called a second time with the same inputs. With this approach, implemented with the <a href="https://CRAN.R-project.org/package=memoise">memoise package</a> in R, you can skip redundant work and save time. 
</p>

<pre><code>library(memoise)
f <- function(n) mean(rnorm(n))
mf = memoise(f)
system.time(x1 <- mf(1e8))
##   user  system elapsed 
##  4.968   0.000   4.973 
system.time(x2 <- mf(1e8))
##   user  system elapsed 
##      0       0       0 
identical(x1, x2)
## [1] TRUE
</code></pre>

## Dependency neglect

<p>
But what if you define multiple functions and nest them? Does a memoized function update results when dependencies change?
</p>

<pre><code>g <- function(x) 2*x
f <- function(x) g(x)
mf <- memoise(f)
mf(1)
## [1] 2 # Correct
g <- function(x) 100*x
mf(1)
## [1] 2 # Memoise does not know that g() changed!
forget(mf) # Throw away old results, compute new ones from scratch.
## [1] TRUE
mf(1)
## [1] 100 # Correct
</code></pre>

## <a href="https://en.wikipedia.org/wiki/Race_condition">Race conditions</a>

<p>
What about parallel computing? What if your code needs multiple simultaneous calls to <code>mf(1)</code>?
</p>

<pre><code>library(parallel)
f <- function(n) rnorm(n)
mf <- memoise(f)
mclapply(c(1, 1), mf, mc.cores = 2)
## [[1]]
## [1] 0.9794243
##
## [[2]]
## [1] 0.03021947
</code></pre>

<p>
Which result was actually stored?
</p>

<pre><code>mf(1)
## [1] 0.4883345 # Niether!
</code></pre>

<p>
As <a href="https://github.com/r-lib/memoise/issues/29">RStudio's Jim Hester explains</a>, multiple processes could simultaneously write to the same file and corrupt the results.
</p>

## Solution

<p>
<a href="https://www.gnu.org/software/make/">Make</a> and its spinoffs resemble memoise, but go they extra mile: they account for dependencies and unlock <a href="https://en.wikipedia.org/wiki/Implicit_parallelism">implicit parallel computing</a>. Such packages <a href="https://cran.r-project.org/web/packages/drake/vignettes/quickstart.html">already exist in R</a>.
</p>
