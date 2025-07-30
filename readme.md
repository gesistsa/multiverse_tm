

# Setup

**Requires R 4.1.0 or newer** We tested our code on R 4.5.1 on Ubuntu
Linux 22.04.

There are two ways to manage your R environment so that the correct
packages are installed:

- Using an isolated environment with `renv`. We also use this to manage
  the dependencies for Docker
- Freestyle and use your global environment. All required packages are
  listed in section “Project Dependencies”.

## Environment using renv

### Linux

Ensure `renv` (version \>= 1.1.4) and `pak` are installed:

``` bash
R -e 'install.packages(c("renv", "pak"))'
```

Then you can activate and restore the environment in R by running:

``` r
options(renv.config.pak.enabled = TRUE)
renv::activate()
renv::restore()
```

### Windows

> [!NOTE]
>
> Although we expect the R scripts in this codebase to work across all
> platforms, it requires a lot of tooling outside of R (e.g., cURL,
> make) that is readily available on Unix-like systems. Your milage with
> Windows will vary and additional tweaking may be required. In case of
> doubt, we recommend using [Windows Subsystem for
> Linux](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux).

Ensure `renv` (version \>= 1.1.4) and
[Rtools](https://cran.r-project.org/bin/windows/Rtools/) are installed.

*Protip:* You can install RTools with winget. Open a PowerShell and
enter `winget install rtools`

Installing `renv`:

``` bash
R -e 'install.packages("renv")'
```

Then you can activate and restore the environment in R by running:

``` r
renv::activate()
renv::restore()
```

### Adding new dependencies

Now all packages should be installed for the virtual environment. If you
need to add new dependencies, you can do the following:

``` r
pak::pkg_install("<new package dependency")
renv::snapshot()
```

This should update the `renv.lock` file with the new dependencies.
Please also add the package you added to the section “Project
Dependencies” at the bottom of this readme.

## Datasets

The following data files should be in the `rawdata` directory.

- [`rawdata/UNGDC_1946-2024.tar.gz`](https://dataverse.harvard.edu/file.xhtml?fileId=11095259&version=13.0)
  (use `make rawdata/UNGDC_1946-2024.tar.gz` to download and check)
- [`rawdata/final_data.RDS`](https://osf.io/3hazf) (use
  `make rawdata/final_data.RDS` to download and check)
- [`Corona-survey_full.dta`](https://search.gesis.org/research_data/SDN-10.7802-2034?doi=10.7802/2034)
  (You must request it via GESIS BASIS)
- `rawdata/stopwords-de.txt` (use `make rawdata/stopwords-de.txt` to
  download and check)
- `rawdata/rawdata/german-gsd-ud-2.5-191206.udpipe` (use
  `make rawdata/rawdata/german-gsd-ud-2.5-191206.udpipe` to download and
  check)

# Docker

> [!WARNING]
>
> Building the docker image can take up to 10 minutes ☠️ ☠️ ☠️

The entire analysis can be run with Docker by using

``` bash
docker compose build
docker compose up
```

Note that `docker compose up` currently runs the debug mode of all
analysis steps.

# Project Dependencies

Major dependencies are listed below [^1]:

``` r
Packages <- c(
    "brms",
    "cowplot",
    "dplyr",
    "furrr",
    "ggplot2",
    "haven",
    "here",
    "keyATM",
    "lexicon",
    "osfr",
    "purrr",
    "quanteda",
    "renv",
    "rlang",
    "rmarkdown",
    "seededlda",
    "SnowballC",
    "stm",
    "stringr",
    "testthat",
    "tidyr",
    "tools",
    "udpipe"
)

pak::pkg_install(packages)
```

# Options

There are options that one can customize; see `.Rprofile`.

[^1]: There are also additional dependencies for developers: `withr` and
    `quarto`
