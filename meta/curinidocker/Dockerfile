FROM ghcr.io/r-hub/evercran/3.6.1

RUN apt update ; apt install -y libxml2-dev libgsl-dev

RUN Rscript -e 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/2019-09-02/bin/linux/bookworm-x86_64/3.6")); install.packages(c("quanteda", "remotes", "sandwich", "lmtest")); '

RUN Rscript -e 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/2019-09-02/bin/linux/bookworm-x86_64/3.6")); remotes::install_github("koheiw/seededlda", ref = "ad0c345a6f05d3cfefd15f3f108a03d7653791b2"); library(quanteda); library(quanteda.seededlda)'

CMD ["R"]


