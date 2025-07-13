intermediate/un/runs/1: un_dfms
	Rscript un02_train.R 1
un_dfms: rawdata/un
	mkdir -p intermediate/un
	Rscript un01_read.R
rawdata/un: rawdata/UNGDC_1946-2024.tar.gz
	mkdir -p rawdata/un
	tar -xzf rawdata/UNGDC_1946-2024.tar.gz -C rawdata/un
	find rawdata/un -name "._*" -delete
rawdata/UNGDC_1946-2024.tar.gz:
	mkdir -p rawdata
	curl -L "https://dataverse.harvard.edu/api/access/datafile/11095259?persistentId=doi:10.7910/DVN/0TJX8Y" -o rawdata/UNGDC_1946-2024.tar.gz
	echo "9154040616d65a3f612deae24bee447a  rawdata/UNGDC_1946-2024.tar.gz" | md5sum -c -
clean:
	rm -rf rawdata
.phony: clean un_dfms

