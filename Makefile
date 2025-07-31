all: chan jankin czymara curini

chan: intermediate/chan/runs/1
jankin: intermediate/jankin/runs/1
czymara: intermediate/czymara/runs/1
curini: intermediate/curini/runs/1

intermediate/curini/runs/1: curini_dfms
	Rscript curini02_train.R 1	
curini_dfms: rawdata/italian-isdt-ud-2.5-191206.udpipe rawdata/zip_texts.rar rawdata/meta_table.tab
	mkdir -p intermediate/czymara
	Rscript curini01_read.R $(DEBUG)
rawdata/italian-isdt-ud-2.5-191206.udpipe:
	mkdir -p rawdata
	curl -L "https://raw.githubusercontent.com/jwijffels/udpipe.models.ud.2.5/master/inst/udpipe-ud-2.5-191206/italian-isdt-ud-2.5-191206.udpipe" -o rawdata/italian-isdt-ud-2.5-191206.udpipe
	echo "0ca1865e00ec3f20c3dcc22c022955a0  rawdata/italian-isdt-ud-2.5-191206.udpipe" | md5sum -c
rawdata/meta_table.tab:
	mkdir -p rawdata
	curl -L "https://dataverse.harvard.edu/api/access/datafile/4291441" -o rawdata/meta_table.tab
	echo "84603176197dbde65c103e454379ae1f  rawdata/meta_table.tab" | md5sum -c
rawdata/zip_texts.rar:
	curl -L "https://dataverse.harvard.edu/api/access/datafile/4291434" -o rawdata/zip_texts.rar
	echo "5470b2e0193a514cad931171ff5185e8  rawdata/zip_texts.rar" | md5sum -c
results/aggregated/chan/1.csv: intermediate/chan/runs/1/brms
	mkdir -p results/aggregated/chan
	Rscript chan05_combine.R 1
intermediate/czymara/runs/1: czymara_dfms
	Rscript czymara02_train.R 1
czymara_dfms: rawdata/stopwords-de.txt rawdata/german-gsd-ud-2.5-191206.udpipe
	mkdir -p intermediate/czymara
	Rscript czymara01_read.R $(DEBUG)
rawdata/stopwords-de.txt:
	mkdir -p rawdata
	curl -L "https://raw.githubusercontent.com/czymara/perceiving-COVID19-in-Germany/refs/heads/master/in/stopwords-de.txt" -o rawdata/stopwords-de.txt
	echo "fa7875d925fb7eccbb082a6cd6e2c37d  rawdata/stopwords-de.txt" | md5sum -c
rawdata/german-gsd-ud-2.5-191206.udpipe:
	mkdir -p rawdata
	curl -L "https://raw.githubusercontent.com/jwijffels/udpipe.models.ud.2.5/master/inst/udpipe-ud-2.5-191206/german-gsd-ud-2.5-191206.udpipe" -o rawdata/german-gsd-ud-2.5-191206.udpipe
	echo "cf7058257ada6f24ecb0a241f10cc918  rawdata/german-gsd-ud-2.5-191206.udpipe" | md5sum -c
intermediate/chan/runs/1/brms: intermediate/chan/runs/1/theta/theta
	Rscript chan04_brms.R 1
intermediate/chan/runs/1/theta/theta: intermediate/chan/runs/1
	Rscript chan03_theta.R 1
intermediate/chan/runs/1: chan_dfms
	Rscript chan02_train.R 1
chan_dfms: rawdata/final_data.RDS
	mkdir -p intermediate/chan
	Rscript chan01_read.R $(DEBUG)
rawdata/final_data.RDS:
	mkdir -p rawdata
	Rscript osf_download.R 3hazf rawdata
	echo "4a3fea6f80a02e0ddf8afaf29abd1e71  rawdata/final_data.RDS" | md5sum -c -
intermediate/jankin/runs/1: jankin_dfms
	Rscript jankin02_train.R 1
jankin_dfms: rawdata/jankin
	mkdir -p intermediate/jankin
	Rscript jankin01_read.R $(DEBUG)
rawdata/jankin: rawdata/UNGDC_1946-2024.tar.gz
	mkdir -p rawdata/jankin
	tar -xzf rawdata/UNGDC_1946-2024.tar.gz -C rawdata/jankin
	find rawdata/jankin -name "._*" -delete
rawdata/UNGDC_1946-2024.tar.gz:
	mkdir -p rawdata
	curl -L "https://dataverse.harvard.edu/api/access/datafile/11095259?persistentId=doi:10.7910/DVN/0TJX8Y" -o rawdata/UNGDC_1946-2024.tar.gz
	echo "9154040616d65a3f612deae24bee447a  rawdata/UNGDC_1946-2024.tar.gz" | md5sum -c -

debug: DEBUG = --debug

debug: chan_dfms jankin_dfms czymara_dfms
	Rscript jankin02_train.R ${DEBUG}
	Rscript chan02_train.R ${DEBUG}
	Rscript czymara02_train.R ${DEBUG}

# Developers only
test:
	Rscript --no-init-file -e "testthat::test_file('tests/lib_tests.R')"
rmd:
	Rscript --no-init-file -e "quarto::quarto_render('readme.rmd', output_file = 'readme.md')"
deploy-hook:
	cp tests/precommit.sh .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit
clean:
	rm -rf rawdata

.phony: clean jankin_dfms chan_dfms czymara_dfms test rmd
