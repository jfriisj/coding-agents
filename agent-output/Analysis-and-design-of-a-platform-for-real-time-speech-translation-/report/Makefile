all:
	pdflatex -interaction=batchmode main || (cat main.log | grep -A 20 \"!\" && exit 1)
	bibtex main
	pdflatex -interaction=batchmode main
	pdflatex -interaction=batchmode main

clean:
	rm -f main.{aux,bbl,blg,dvi,fdb_latexmk,fls,log,toc,pdf}
