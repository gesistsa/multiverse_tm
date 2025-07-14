FROM rocker/r-ver:4.5.0
RUN echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >>"${R_HOME}/etc/Rprofile.site"

RUN apt update; apt install curl make xz-utils libcurl4-gnutls-dev libssl-dev libpoppler-cpp-dev zlib1g-dev libicu-dev libxml2-dev -y

WORKDIR /root/multiverse_tm

COPY . .

RUN R --slave -e 'install.packages(c("renv", "pak"))'

RUN R --slave -e 'options(renv.config.pak.enabled = TRUE); renv::restore()'

CMD ["R", "--slave", "-e", "options(renv.config.pak.enabled = TRUE); renv::restore()"]

CMD ["make", "rawdata/UNGDC_1946-2024.tar.gz"]

CMD ["Rscript", "jankin01_read.R", "--debug"]