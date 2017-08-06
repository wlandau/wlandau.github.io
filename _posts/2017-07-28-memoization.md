---
layout: post
title: "The strengths and perils of traditional memoization"
tags: R
---

<p>
<a href="https://en.wikipedia.org/wiki/Memoization">Memoization</a> is the practice of storing the return values of function calls for later use. A memoized function simply reads a prior result if called a second time with the same inputs. It is a well-established technique across many languages for skipping redundant work and saving time. In R, the <a href="https://CRAN.R-project.org/package=memoise">memoise package</a> by <a href="https://github.com/hadley">Hadley Wickham</a>, <a href="https://github.com/jimhester">Jim Hester</a>, <a href="https://github.com/krlmlr">Kirill Müller</a>, and others is one of the most elegant and useful packages I have ever seen. 
</p>

## Efficiency gains

Benchmarks are application-dependent. Here is just a taste.

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

But despite the appeal and promise, traditional memoisation has potential pitfalls. From my perspective, the most concerning are dependency neglect and <a href="https://en.wikipedia.org/wiki/Race_condition">race conditions</a>.

## Dependency neglect

<p>
What if you define multiple functions and nest them? Does a memoized function update the results when dependencies change?
</p>

<pre><code>g <- function(x) { 
  2*x + rnorm(1)
}
f <- function(x) g(x)
mf <- memoise(f)
mf(1)
## [1] 0.9391441 # Correct
g <- function(x) {
  1e4*x + rnorm(1)
}
mf(1)
## [1] 0.9391441 # Memoise does not know that g() changed!
forget(mf) # Throw away old results, get the next one from scratch.
## [1] TRUE
mf(1)
## [1] 9999.867 # Correct
</code></pre>

Fortunately, in the <a href="https://CRAN.R-project.org/package=memoise">memoise package</a>, you can force `mf()` to depend on `g()`. Though in an ideal world, you would not have to.

<pre><code>mf = memoise(f, ~g)
mf(1)
## [1] 10000.56
mf(1)
## [1] 10000.56
g <- function(x) { 
  2*x + rnorm(1)
}
mf(1)
## [1] 0.08486043
mf(1)
## [1] 0.08486043
</code></pre>

To look for the immediate dependencies of a function, I recommend the <a href="https://CRAN.R-project.org/package=CodeDepends">CodeDepends package</a>. Just keep in mind that `g()` may have dependencies too.

<pre><code>library(CodeDepnds)
getInputs(body(f))
## An object of class "ScriptNodeInfo"
## Slot "files":
## character(0)
## 
## Slot "strings":
## character(0)
## 
## Slot "libraries":
## character(0)
## 
## Slot "inputs":
## [1] "x"
## 
## Slot "outputs":
## character(0)
## 
## Slot "updates":
## character(0)
## 
## Slot "functions":
##  g 
## NA 
## 
## Slot "removes":
## character(0)
## 
## Slot "nsevalVars":
## character(0)
## 
## Slot "sideEffects":
## character(0)
## 
## Slot "code":
## g(x)
</code></pre>

## <a href="https://en.wikipedia.org/wiki/Race_condition">Race conditions</a>

<p>
And what about parallel computing? What if your code has multiple simultaneous calls to <code>mf(1)</code>?
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
## [1] 0.4883345
</code></pre>

<p>
As <a href="https://github.com/r-lib/memoise/issues/29">RStudio's Jim Hester explains</a>, multiple processes could simultaneously write to the same file and corrupt the results.
</p>

## A solution

<p>
<a href="https://www.gnu.org/software/make/">Make</a> and its spinoffs resemble <a href="https://CRAN.R-project.org/package=memoise">memoise</a>, but go they extra mile: they account for dependencies and unlock <a href="https://en.wikipedia.org/wiki/Implicit_parallelism">implicit parallel computing</a>. Such packages <a href="https://github.com/wlandau-lilly/drake">already exist in R</a>.
</p>
