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

Fortunately, in the <a href="https://CRAN.R-project.org/package=memoise">memoise package</a>, you can manually force `mf()` to react to changes to `g()`.

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
What if your code has multiple simultaneous calls to <code>mf(1)</code>?
</p>

<pre><code>library(parallel)
f <- function(x) rnorm(n = 1, mean = x)
mf <- memoise(f)
unlist(mclapply(1:2, mf, mc.cores = 2))
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] -0.4580604  1.7078366
</code></pre>

<p>
Can you reuse the previous results?
</p>

<pre><code>unlist(mclapply(1:2, mf, mc.cores = 2))
</code></pre>
<pre style = "background: transparent"><code style = "background: transparent">## [1] 0.2213628 1.7208111
</code></pre>

<p>
As <a href="https://github.com/r-lib/memoise/issues/29">RStudio's Jim Hester explains</a>, multiple processes could simultaneously write to the same file and corrupt the results.
</p>

## Alternatives

<p>
<a href="https://www.gnu.org/software/make/">Make</a> and its spinoffs resemble <a href="https://CRAN.R-project.org/package=memoise">memoise</a>, but go they extra mile: they automatically account for dependencies and unlock <a href="https://en.wikipedia.org/wiki/Implicit_parallelism">implicit parallel computing</a>. There are already <a href="https://github.com/wlandau-lilly/drake">Make-like packages just for R</a>.
</p>
