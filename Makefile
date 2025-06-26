res/keyATM: res data/toks.RDS
	mkdir res/keyATM
	Rscript keyATM.R
res:
	mkdir res
data/toks.RDS: data/un_corpus.RDS
	Rscript toks.R
data/un_corpus.RDS: data
	Rscript read.R
data:
	mkdir data
	tar -xzf UNGDC_1946-2024.tar.gz -C data
	find . -name "._*" -delete
clean:
	rm -rf data

.phony: data clean
