FROM rocker/r-ver:4.5.0

## NOTE: Don't update this line by hand
RUN apt update; apt install -y curl make cmake git libglpk-dev libarchive-dev libcurl4-openssl-dev libicu-dev libxml2-dev libssl-dev pandoc libx11-dev zlib1g-dev mecab libmecab-dev mecab-ipadic-utf8

ARG STU_VERSION="2.7.85"

RUN curl -q -o /tmp/stu_amd64.deb -L https://github.com/kunegis/stu/releases/download/${STU_VERSION}/stu_amd64.deb \
  && dpkg -i /tmp/stu_amd64.deb \
  && rm /tmp/stu_amd64.deb

RUN R -e 'install.packages(c("renv", "pak"), lib=.Library)'

WORKDIR /root/multiverse_tm

COPY renv.lock renv.lock

RUN R -e "options(renv.config.pak.enabled = TRUE); renv::restore(lockfile = \"renv.lock\", library = .Library)"

CMD ["stu", "@dockertest"]
