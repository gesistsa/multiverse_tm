all: chan jankin czymara curini tvinnereim takano

chan: intermediate/chan/runs/1
jankin: intermediate/jankin/runs/1
czymara: intermediate/czymara/runs/1
curini: intermediate/curini/runs/1
tvinnereim: intermediate/tvinnereim/runs/1
takano: intermediate/takano/runs/1

## takano
results/aggregated/takano/3.csv: intermediate/takano/runs/3
	mkdir -p results/aggregated/takano
	Rscript takano/03_combine.R 3
intermediate/takano/runs/3: takano_dfms
	Rscript takano/02_train.R 3
results/aggregated/takano/2.csv: intermediate/takano/runs/2
	mkdir -p results/aggregated/takano
	Rscript takano/03_combine.R 2
intermediate/takano/runs/2: takano_dfms
	Rscript takano/02_train.R 2
results/aggregated/takano/1.csv: intermediate/takano/runs/1
	mkdir -p results/aggregated/takano
	Rscript takano/03_combine.R 1
intermediate/takano/runs/1: takano_dfms
	Rscript takano/02_train.R 1
takano_dfms: rawdata/data_cleaned.csv rawdata/data_pilot_cleaned.csv
	mkdir -p intermediate/takano
	Rscript takano/01_read.R $(DEBUG)	
rawdata/data_cleaned.csv:
	mkdir -p rawdata
	Rscript -e "tmmv.osf_download('ecmt6')"
	echo "a3caa1f91acb327b2d026601ff2a8a0c  rawdata/data_cleaned.csv" | md5sum -c
rawdata/data_pilot_cleaned.csv:
	mkdir -p rawdata
	Rscript -e "tmmv.osf_download('k6h39')"
	echo "4a0dfd051130d096f7fd07315a38bfc4  rawdata/data_pilot_cleaned.csv" | md5sum -c

# tvinnereim
results/aggregated/tvinnereim/3.csv: intermediate/tvinnereim/runs/3
	mkdir -p results/aggregated/tvinnereim
	Rscript tvinnereim/03_combine.R 3
intermediate/tvinnereim/runs/3: tvinnereim_dfms
	Rscript tvinnereim/02_train.R 3
results/aggregated/tvinnereim/2.csv: intermediate/tvinnereim/runs/2
	mkdir -p results/aggregated/tvinnereim
	Rscript tvinnereim/03_combine.R 2
intermediate/tvinnereim/runs/2: tvinnereim_dfms
	Rscript tvinnereim/02_train.R 2
results/aggregated/tvinnereim/1.csv: intermediate/tvinnereim/runs/1
	mkdir -p results/aggregated/tvinnereim
	Rscript tvinnereim/03_combine.R 1
intermediate/tvinnereim/runs/1: tvinnereim_dfms
	Rscript tvinnereim/02_train.R 1
tvinnereim_dfms: rawdata/norwegian-bokmaal-ud-2.5-191206.udpipe rawdata/ncp-stm-data.csv
	mkdir -p intermediate/tvinnereim
	Rscript tvinnereim/01_read.R $(DEBUG)
rawdata/norwegian-bokmaal-ud-2.1-20180111.udpipe:
	mkdir -p rawdata
	curl -L "https://github.com/bnosac/udpipe.models.ud/raw/refs/heads/master/models/norwegian-bokmaal-ud-2.1-20180111.udpipe" -o rawdata/norwegian-bokmaal-ud-2.1-20180111.udpipe
	echo "0ef59252b89073c1980177d72304929e  rawdata/norwegian-bokmaal-ud-2.1-20180111.udpipe" | md5sum -c
rawdata/ncp-stm-data.csv:
	mkdir -p rawdata
	curl -L "https://dataverse.harvard.edu/api/access/datafile/:persistentId?persistentId=doi:10.7910/DVN/28689/KO9T0Z" -o rawdata/ncp-stm-data.csv
	echo "6072f1004cc368c476f7de3c28021d6d  rawdata/ncp-stm-data.csv" | md5sum -c

# curini
results/aggregated/curini/3.csv: intermediate/curini/runs/3
	mkdir -p results/aggregated/curini
	Rscript curini/03_regression.R 3
intermediate/curini/runs/3: curini_dfms
	Rscript curini/02_train.R 3
results/aggregated/curini/2.csv: intermediate/curini/runs/2
	mkdir -p results/aggregated/curini
	Rscript curini/03_regression.R 2
intermediate/curini/runs/2: curini_dfms
	Rscript curini/02_train.R 2
results/aggregated/curini/1.csv: intermediate/curini/runs/1
	mkdir -p results/aggregated/curini
	Rscript curini/03_regression.R 1
intermediate/curini/runs/1: curini_dfms
	Rscript curini/02_train.R 1	
curini_dfms: rawdata/italian-isdt-ud-2.5-191206.udpipe rawdata/zip_texts.rar rawdata/meta_table.tab
	mkdir -p intermediate/curini
	Rscript curini/01_read.R $(DEBUG)
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

# czymara
results/aggregated/czymara/3.csv: intermediate/czymara/3
	mkdir -p results/aggregated/czymara
	Rscript czymara/03_combine.R 3
intermediate/czymara/runs/3: czymara_dfms
	Rscript czymara/02_train.R 3
results/aggregated/czymara/2.csv: intermediate/czymara/2
	mkdir -p results/aggregated/czymara
	Rscript czymara/03_combine.R 2
intermediate/czymara/runs/2: czymara_dfms
	Rscript czymara/02_train.R 2
results/aggregated/czymara/1.csv: intermediate/czymara/1
	mkdir -p results/aggregated/czymara
	Rscript czymara/03_combine.R 1
intermediate/czymara/runs/1: czymara_dfms
	Rscript czymara/02_train.R 1
czymara_dfms: rawdata/stopwords-de.txt rawdata/german-gsd-ud-2.5-191206.udpipe
	mkdir -p intermediate/czymara
	Rscript czymara/01_read.R $(DEBUG)
rawdata/stopwords-de.txt:
	mkdir -p rawdata
	curl -L "https://raw.githubusercontent.com/czymara/perceiving-COVID19-in-Germany/refs/heads/master/in/stopwords-de.txt" -o rawdata/stopwords-de.txt
	echo "fa7875d925fb7eccbb082a6cd6e2c37d  rawdata/stopwords-de.txt" | md5sum -c
rawdata/german-gsd-ud-2.5-191206.udpipe:
	mkdir -p rawdata
	curl -L "https://raw.githubusercontent.com/jwijffels/udpipe.models.ud.2.5/master/inst/udpipe-ud-2.5-191206/german-gsd-ud-2.5-191206.udpipe" -o rawdata/german-gsd-ud-2.5-191206.udpipe
	echo "cf7058257ada6f24ecb0a241f10cc918  rawdata/german-gsd-ud-2.5-191206.udpipe" | md5sum -c

# chan
results/aggregated/chan/3.csv: intermediate/chan/runs/3/brms
	mkdir -p results/aggregated/chan
	Rscript chan/05_combine.R 3
intermediate/chan/runs/3/brms: intermediate/chan/runs/3/theta/theta
	Rscript chan/04_brms.R 3
intermediate/chan/runs/3/theta/theta: intermediate/chan/runs/3
	Rscript chan/03_theta.R 3
intermediate/chan/runs/3: chan_dfms
	Rscript chan/02_train.R 3
results/aggregated/chan/2.csv: intermediate/chan/runs/2/brms
	mkdir -p results/aggregated/chan
	Rscript chan/05_combine.R 2
intermediate/chan/runs/2/brms: intermediate/chan/runs/2/theta/theta
	Rscript chan/04_brms.R 2
intermediate/chan/runs/2/theta/theta: intermediate/chan/runs/2
	Rscript chan/03_theta.R 2
intermediate/chan/runs/2: chan_dfms
	Rscript chan/02_train.R 2
results/aggregated/chan/1.csv: intermediate/chan/runs/1/brms
	mkdir -p results/aggregated/chan
	Rscript chan/05_combine.R 1
intermediate/chan/runs/1/brms: intermediate/chan/runs/1/theta/theta
	Rscript chan/04_brms.R 1
intermediate/chan/runs/1/theta/theta: intermediate/chan/runs/1
	Rscript chan/03_theta.R 1
intermediate/chan/runs/1: chan_dfms
	Rscript chan/02_train.R 1
chan_dfms: rawdata/final_data.RDS
	mkdir -p intermediate/chan
	Rscript chan/01_read.R $(DEBUG)
rawdata/final_data.RDS:
	mkdir -p rawdata
	Rscript -e "tmmv.osf_download('3hazf')"
	echo "4a3fea6f80a02e0ddf8afaf29abd1e71  rawdata/final_data.RDS" | md5sum -c -

# jankin
intermediata/jankin/runs/3/theta: intermediate/jankin/runs/3
	mkdir -p intermediate/jankin/runs/3/theta
	Rscript jankin/03_combine.R 3
intermediate/jankin/runs/3: jankin_dfms
	Rscript jankin/02_train.R 3
intermediata/jankin/runs/2/theta: intermediate/jankin/runs/2
	mkdir -p intermediate/jankin/runs/2/theta
	Rscript jankin/03_combine.R 2
intermediate/jankin/runs/2: jankin_dfms
	Rscript jankin/02_train.R 2
intermediata/jankin/runs/1/theta: intermediate/jankin/runs/1
	mkdir -p intermediate/jankin/runs/1/theta
	Rscript jankin/03_combine.R 1
intermediate/jankin/runs/1: jankin_dfms
	Rscript jankin/02_train.R 1
jankin_dfms: rawdata/jankin
	mkdir -p intermediate/jankin
	Rscript jankin/01_read.R $(DEBUG)
rawdata/jankin: rawdata/UNGDC_1946-2024.tar.gz
	mkdir -p rawdata/jankin
	tar -xzf rawdata/UNGDC_1946-2024.tar.gz -C rawdata/jankin
	find rawdata/jankin -name "._*" -delete
rawdata/UNGDC_1946-2024.tar.gz:
	mkdir -p rawdata
	curl -L "https://dataverse.harvard.edu/api/access/datafile/11095259?persistentId=doi:10.7910/DVN/0TJX8Y" -o rawdata/UNGDC_1946-2024.tar.gz
	echo "9154040616d65a3f612deae24bee447a  rawdata/UNGDC_1946-2024.tar.gz" | md5sum -c -

# DEBUG
debug: DEBUG = --debug

debug: chan_dfms jankin_dfms czymara_dfms
	Rscript jankin/02_train.R ${DEBUG}
	Rscript chan/02_train.R ${DEBUG}
	Rscript czymara/02_train.R ${DEBUG}

# Developers only
test:
	Rscript --no-init-file -e "testthat::test_file('dev/lib_tests.R')"
rmd:
	Rscript --no-init-file dev/cache_requirements.R
	Rscript --no-init-file dev/update_dockerfile.R
	Rscript --no-init-file -e "quarto::quarto_render('readme.rmd', output_file = 'readme.md')"
deploy-hook:
	cp dev/precommit.sh .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit
clean:
	rm -rf rawdata

.phony: clean jankin_dfms chan_dfms czymara_dfms test rmd
