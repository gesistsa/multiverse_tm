FROM rocker/r-ver:4.5.0

## NOTE: Don't update this line by hand
RUN apt update; apt install -y curl make libarchive-dev libcurl4-openssl-dev libicu-dev libxml2-dev libssl-dev pandoc libx11-dev zlib1g-dev mecab libmecab-dev mecab-ipadic-utf8

RUN R -e 'install.packages(c("renv", "pak"), lib=.Library)'

WORKDIR /root/multiverse_tm

COPY renv.lock renv.lock

RUN R -e "options(renv.config.pak.enabled = TRUE); renv::restore(lockfile = \"renv.lock\", library = .Library)"

CMD ["make", "debug"]
