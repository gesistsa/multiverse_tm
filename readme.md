# Setup

**Requires R 4.1.0 or newer**

There are two ways to manage your R environment so that the correct packages are installed:

- Using an isolated environment with `renv`. We also use this to manage the dependencies for Docker
- Freestyle and use your global environment. All required packages are listed in section "Project Dependencies".

## Environment using renv

Ensure `renv` (version >= 1.1.4) and `pak` are installed:

```bash
R -e 'install.packages(c("renv", "pak"))'
```

Then you can activate and restore the environment in R by running:

```r
options(renv.config.pak.enabled = TRUE)
renv::activate()
renv::restore()
```

Now all packages should be installed for the virtual environment. If you need to add new dependencies, you can do the following:

```r
pak::pkg_install("<new package dependency")
renv::snapshot()
```

This should update the `renv.lock` file with the new dependencies. Please also add the package you added to the section "Project Dependencies" at the bottom of this readme.


## Datasets

The following data files should be in the `rawdata` directory.

* [`rawdata/UNGDC_1946-2024.tar.gz`](https://dataverse.harvard.edu/file.xhtml?fileId=11095259&version=13.0) (use `make rawdata/UNGDC_1946-2024.tar.gz` to download and check)
* [`rawdata/final_data.RDS`](https://osf.io/3hazf) (use `make rawdata/final_data.RDS` to download and check)


# Docker

> [!WARNING]  
> Warning: Building the docker image can take up to 10 minutes ☠️ ☠️ ☠️

The entire analysis can be run with Docker by using

```bash
docker compose build
docker compose up
```

Note that `docker compose up` currently runs the debug mode of all analysis steps.

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
    "osfr",
    "purrr",
    "seededlda",
    "textstem"
)

pak::pkg_install(packages)
```