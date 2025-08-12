FROM rocker/r-ver:4.5.0

RUN apt update; apt install curl make xz-utils libcurl4-gnutls-dev libssl-dev libpoppler-cpp-dev zlib1g-dev libicu-dev libxml2-dev mecab libmecab-dev mecab-ipadic-utf8 -y

RUN R -e 'install.packages(c("renv", "pak"), lib=.Library)'

WORKDIR /root/multiverse_tm

COPY renv.lock renv.lock

RUN R -e "options(renv.config.pak.enabled = TRUE); renv::restore(lockfile = \"renv.lock\", library = .Library)"

CMD ["make", "debug"]
