un_dfms : rawdata/un
	mkdir -p intermediate/un
	Rscript un01_read.R
rawdata/un:
	mkdir -p rawdata/un
	tar -xzf rawdata/UNGDC_1946-2024.tar.gz -C rawdata/un
	find rawdata/un -name "._*" -delete
clean:
	rm -rf rawdata
.phony: clean un_dfms

