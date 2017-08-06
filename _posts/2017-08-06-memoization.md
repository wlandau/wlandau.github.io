---
layout: post
title: "On the strengths and perils of traditional memoization"
tags: 
  - R
---

<p>
<a href="https://en.wikipedia.org/wiki/Memoization">Memoization</a> is the practice of storing the return values of function calls for later use, a well-established technique across many languages for skipping redundant work and saving time. In R, the <a href="https://CRAN.R-project.org/package=memoise">memoise package</a> by <a href="https://github.com/hadley">Hadley Wickham</a>, <a href="https://github.com/jimhester">Jim Hester</a>, <a href="https://github.com/krlmlr">Kirill Müller</a>, and others is one of the most elegant and useful packages I know. 
</p>

## Efficiency gains

A memoized function simply returns a prior result if called a second time with the same inputs. Here is just a taste of the time savings.

<pre><code>library(memoise)
f <- function(n) mean(rnorm(n))
mf = memoise(f)
system.time(x1 <- mf(1e8))
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">##   user  system elapsed 
##  4.968   0.000   4.973 
</code></pre>
<pre><code>system.time(x2 <- mf(1e8))
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">##   user  system elapsed 
##      0       0       0 
</code></pre>
<pre><code>identical(x1, x2)
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] TRUE
</code></pre>

However, there are good reasons to apply caution when using traditional memoization.

## Dependencies

<p>
What if you define multiple functions and nest them? Does a memoized function update the results when non-local dependencies change?
</p>

<pre><code>g <- function(x) { 
  2*x + rnorm(1)
}
f <- function(x) g(x)
mf <- memoise(f)
mf(1)
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] 0.9391441 # Correct
</code></pre>
<pre><code>g <- function(x) {
  1e4 * x + rnorm(1)
}
mf(1)
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] 0.9391441 # Memoise does not know that g() changed!
</code></pre>
<pre><code>forget(mf) # Throw away old results, get the next one from scratch.
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] TRUE
</code></pre>
<pre><code>mf(1)
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] 9999.867 # Correct
</code></pre>

Fortunately, with the <a href="https://CRAN.R-project.org/package=memoise">memoise package</a>, you can manually force `mf()` to react to changes to `g()`.

<pre><code>mf = memoise(f, ~g)
mf(1)
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] 10000.56
</code></pre>
<pre><code>mf(1)
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] 10000.56
</code></pre>
<pre><code>g <- function(x) { 
  2*x + rnorm(1)
}
mf(1)
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] 0.08486043
</code></pre>
<pre><code>mf(1)
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] 0.08486043
</code></pre>

To look for the immediate dependencies of a function, you can use `findGlobals()` from <a href="http://homepage.divms.uiowa.edu/~luke/">Luke Tierney</a>'s long-established <a href="https://CRAN.R-project.org/package=codetools">codetools</a> package. Alternatively, <a href="https://CRAN.R-project.org/package=CodeDepends">CodeDepends</a> is a more recent effort by <a href="https://github.com/gmbecker">Gabe Becker</a>, <a href="https://github.com/duncantl">Duncan Temple Lang</a>, and others, and it <a href="https://cran.r-project.org/package=CodeDepends/vignettes/intro.html">goes beyond simply finding dependencies</a>. Whatever tool you use, just keep in mind that no static code analysis tool is perfect, and dependencies like `g()` may have dependencies of their own.

<pre><code>library(codetools)
findGlobals(f)
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] "g"
</code></pre>
<pre><code>library(CodeDepnds)
str(getInputs(body(f)))
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## Formal class 'ScriptNodeInfo' [package "CodeDepends"] with 11 slots
##   ..@ files      : chr(0) 
##   ..@ strings    : chr(0) 
##   ..@ libraries  : chr(0) 
##   ..@ inputs     : chr "x"
##   ..@ outputs    : chr(0) 
##   ..@ updates    : chr(0) 
##   ..@ functions  : Named logi NA
##   .. ..- attr(*, "names")= chr "g"
##   ..@ removes    : chr(0) 
##   ..@ nsevalVars : chr(0) 
##   ..@ sideEffects: chr(0) 
##   ..@ code       : language g(x)
</code></pre>

## Parallel computing

<p>
What if your code has multiple simultaneous calls to <code>mf(1)</code>? First, notice how memoization can fail if you use the default in-memory cache.
</p>

<pre><code>library(parallel)
f <- function(n) rnorm(n)
mf <- memoise(f)
run <- function(){
  output <- mclapply(c(1, 1), mf, mc.cores = 2)
  unlist(output)
}
run()
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] -0.1669109  1.1784395
</code></pre>
<pre><code>run()
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] -0.4694902  1.8671464 # new results computed
</code></pre>

<p>
At minimum, I recommend the file system cache.
</p>

<pre><code>mf <- memoise(f, cache = cache_filesystem("my_cache"))
run()
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] -0.01171047 -0.01171047
</code></pre>
<pre><code>run()
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] -0.01171047 -0.01171047
</code></pre>

<p>
But even then, you should avoid calling the same memoized function on the same inputs twice simultaneously. As <a href="https://github.com/r-lib/memoise/issues/29">RStudio's Jim Hester explains</a>, multiple processes could write to the same file at the same time and corrupt the results. In general, this sort of unpredictable behavior is called a <a href="https://en.wikipedia.org/wiki/Race_condition">race condition</a>, and it is the bane of any kind of parallel computing.
</p>

## Solutions

<p>
<a href="https://www.gnu.org/software/make/">Make</a> and its spinoffs resemble <a href="https://CRAN.R-project.org/package=memoise">memoise</a>, but go they extra mile: they automatically account for dependencies and unlock <a href="https://en.wikipedia.org/wiki/Implicit_parallelism">implicit parallel computing</a>. There are already <a href="https://github.com/wlandau-lilly/drake">Make-like packages just for R</a>.
</p>
