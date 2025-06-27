res/seededlda: data/toks.RDS
	mkdir -p res/seededlda
	Rscript seededlda.R
res/keyATM: data/toks.RDS
	mkdir -p res/keyATM
	Rscript keyATM.R
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
