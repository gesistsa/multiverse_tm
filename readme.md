# Setup

Requires R 4.1.0 or newer

## Environment using renv

Ensure `renv` (version 1.1.4) and `pak` are installed:

```bash
R --slave -e 'install.packages(c("renv", "pak"))'
```

Then you can activate and restore the environment in R by running:

```r
renv::activate()
renv::restore()
```

## Datasets

The following data files should be in the `rawdata` directory.

* [`rawdata/UNGDC_1946-2024.tar.gz`](https://dataverse.harvard.edu/file.xhtml?fileId=11095259&version=13.0) (use `make rawdata/UNGDC_1946-2024.tar.gz` to download and check)


# Docker

> [!WARNING]  
> Warning: Building takes about 10 minutes ☠️ ☠️ ☠️

The entire analysis can be run with Docker by using

```bash
docker compose build
docker compose up
```

Note that `docker compose up` simply runs the `entrypoint.sh` script. So if modifications of commands are necessary, just edit the script which should not require rebuilding the docker container from scratch.

# Project Dependencies

Major dependencies are listed below:

```r
packages <- c(
    "here",
    "readtext",
    "quanteda",
    "stringr",
    "purrr",
    "testthat",
    "keyATM",
    "SnowballC"
)

pak::pkg_install(packages)
```