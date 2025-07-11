rawdata/un:
	mkdir rawdata/un
	tar -xzf rawdata/UNGDC_1946-2024.tar.gz -C rawdata/un
	find rawdata/un -name "._*" -delete
rawdata:
	mkdir rawdata
clean:
	rm -rf rawdata
.phony: clean
