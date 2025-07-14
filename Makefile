chan_dfms: rawdata/final_data.RDS
	mkdir -p intermediate/chan
	Rscript chan01_read.R
rawdata/final_data.RDS:
	mkdir -p rawdata
	Rscript osf_download.R 3hazf rawdata
	echo "4a3fea6f80a02e0ddf8afaf29abd1e71  rawdata/final_data.RDS" | md5sum -c -
intermediate/jankin/runs/1: jankin_dfms
	Rscript jankin02_train.R 1
jankin_dfms: rawdata/jankin
	mkdir -p intermediate/jankin
	Rscript jankin01_read.R
rawdata/jankin: rawdata/UNGDC_1946-2024.tar.gz
	mkdir -p rawdata/jankin
	tar -xzf rawdata/UNGDC_1946-2024.tar.gz -C rawdata/jankin
	find rawdata/jankin -name "._*" -delete
rawdata/UNGDC_1946-2024.tar.gz:
	mkdir -p rawdata
	curl -L "https://dataverse.harvard.edu/api/access/datafile/11095259?persistentId=doi:10.7910/DVN/0TJX8Y" -o rawdata/UNGDC_1946-2024.tar.gz
	echo "9154040616d65a3f612deae24bee447a  rawdata/UNGDC_1946-2024.tar.gz" | md5sum -c -
clean:
	rm -rf rawdata
.phony: clean jankin_dfms
