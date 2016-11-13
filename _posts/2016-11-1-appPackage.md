---
layout: post
title: "This Shiny app is a package! This package is a Shiny app!"
---

Do you like the interactivity of <a href="http://shiny.rstudio.com/">Shiny apps</a>? Do you also like the modularity and <a href="http://r-pkgs.had.co.nz/tests.html">unit testing</a> of <a href="http://r-pkgs.had.co.nz/">R packages</a>? Check out <a href="https://github.com/wlandau/appPackage">this small example</a> to get the best of both worlds.

# It's a Shiny app!

The customary <a href="http://shiny.rstudio.com/articles/single-file.html"><code>app.R</code></a> is in the root directory, so you can launch the project as a Shiny app on a server as is. No package installation is required. Instead, <code>devtools::load_all()</code> in <code>app.R</code> automatically loads all the required R scripts and data files.

# It's a package!

Since <code>app.R</code> is listed in <a href="http://r-pkgs.had.co.nz/package.html"><code>.Rbuildignore</code></a>, you can install the package as is.

<pre><code>install_github("wlandau/appPackage")
</code></pre>

Then, you can run the Shiny app locally.

<pre><code>library(appPackage)
my_app()
</code></pre>

# But what if my app uses compiled code?

Follow the <a href="https://cran.r-project.org/doc/manuals/r-release/R-exts.html#System-and-foreign-language-interfaces">CRAN directions</a> to build your package on top of <a href="https://en.wikipedia.org/wiki/C_(programming_language)">C</a>, <a href="https://en.wikipedia.org/wiki/Fortran">Fortran</a>, or whatever <a href="https://en.wikipedia.org/wiki/Compiled_language">compiled language</a> you're using. Then, all you need is an `app.R` that installs the package on the server and then launches your app with a function call. For this example, the server-side `app.R` would look like this.

<pre><code>install_github("wlandau/appPackage")
library(appPackage)
my_app()
</code></pre>

Here, feel free to discard the <code>app.R</code> inside the package and remove the <code>app.R</code> listing from <code>.Rbuildignore</code>.


# What of my project gets too big and messy?

Overambitious projects tend to get bloated, cluttered, and slow, especially when interactivity and substance fall under the same roof. If you do serious computation behind the scenes in <code>xyzShinyApp</code>, you could encapsulate the hidden core functionality in a separate package: say, <code>xyzEngine</code>. I used this exact approach in my dissertation project. Package <code><a href="https://github.com/wlandau/fbseq">fbseq</a></code> processes user input and <a href="https://en.wikipedia.org/wiki/Markov_chain_Monte_Carlo">Monte Carlo</a> output, and <code><a href="https://github.com/wlandau/fbseqCUDA">fbseqCUDA</a></code> actually fits the model given an already-parsed set of instructions.
