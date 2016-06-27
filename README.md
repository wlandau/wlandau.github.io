Repo for my blog and online portfolio.

# Making the `_includes` files

I tried to use [a plugin](http://wolfslittlestore.be/2013/10/rendering-markdown-in-jekyll/) to make jekyll automatically render Markdown files, but GitHub ignores most plugins for security reasons. Thus, I have to convert Markdown to HTML by hand. The `_inlcudes/*.html` files are made from the analogous
`_source/*.md` files with `pandoc`. Just use the `Makefile`.
