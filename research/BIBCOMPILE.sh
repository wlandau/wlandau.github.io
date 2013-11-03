#!/bin/bash

pdflatex publications.tex
bibtex publications
pdflatex publications.tex

cp publications.bbl ../cv/cv.bbl
cd ../cv
pdflatex cv.tex