---
layout: post
title: "This Shiny app is a package! This package is a Shiny app!"
---

Do you like the interactivity of <a href="http://shiny.rstudio.com/">Shiny apps</a>? Do you also like the modularity and <a href="http://r-pkgs.had.co.nz/tests.html">unit testing</a> of <a href="http://r-pkgs.had.co.nz/">R packages</a>? If you follow <a href="https://github.com/wlandau/appPackage">my small example on GitHub</a>, your next project can be both!

# It's a Shiny app!

The customary <a href=http://shiny.rstudio.com/articles/single-file.html><code>app.R</code></a> in the root directory, so you can launch the project as a Shiny app on a server as is. No package installation is required. Instead, <code>devtools::load_all()</code> in <code>app.R</code> automatically loads all the supplementary R scripts and data files required.

# It's a package!

Since <code>app.R</code> is listed in <a href="http://r-pkgs.had.co.nz/package.html"><code>.Rbuildignore</code></a>, you can install the package as is.

<pre><code>
install_github("wlandau/appPackage")
</code></pre>

Then, you can run the Shiny app locally.

<pre><code>
library(appPackage)
my_app()
</code></pre>
