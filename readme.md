# README


- [About](#about)
  - [Abstract](#abstract)
  - [Overview](#overview)
- [Setup](#setup)
  - [Environment using renv](#environment-using-renv)
    - [If you are using Windows](#if-you-are-using-windows)
    - [Restore the `renv` environment](#restore-the-renv-environment)
    - [Adding new dependencies](#adding-new-dependencies)
  - [Docker](#docker)
  - [Project Dependencies](#project-dependencies)
  - [Options](#options)
- [Reproducing the results](#reproducing-the-results)
  - [Notes about `meta/curinidocker`](#notes-about-metacurinidocker)
- [License](#license)
- [References](#references)

# About

Replication repository for *Beyond beyond standardization: Studying
robustness of empirical claims based on topic modeling through
multiverse analysis*

Published in *Communication Methods and Measures* ([DOI:
10.1080/19312458.2026.2714769](https://doi.org/10.1080/19312458.2026.2714769))

by: [Paul Balluff](https://orcid.org/0000-0001-9548-3225), [Christina
Viehmann](https://orcid.org/0000-0001-6673-0987), [Maximilian
Linde](https://orcid.org/0000-0001-8421-090X), [Yannik
Peters](https://orcid.org/0009-0001-4879-5477), [Jun
Sun](https://orcid.org/0000-0002-4789-7316), and [Chung-hong
Chan](https://orcid.org/0000-0002-6232-7530)

*All authors contributed to this project equally. The order of the names
was determined by a random draw.*

## Abstract

> While topic modeling is widely used, some scholars have already
> announced that the application of topic modeling in social science
> research is impossible to standardize. Meanwhile, researchers have to
> make numerous methodological decisions, yet base their empirical
> claims on just one topic model. This raises the question of robustness
> about those claims. In this study, we apply the framework of
> preregistered multiverse analysis to evaluate the robustness of
> previous empirical claims from six studies that were based on topic
> modeling. Based on the Open Science materials of these six studies, we
> slightly modify the original topic modeling procedures, such as
> preprocessing, number of topic clusters, and topic modeling algorithm,
> to other defensible choices and determine whether the empirical claims
> remain consistent. Even though we observe that certain empirical
> claims are more robust, most claims are distorted considerably by
> changes to the modeling options. The contributions of this study are
> twofold. First, we confirm that empirical claims based on just one
> topic model might not be robust against numerous researchers degrees
> of freedom. Second, we advocate a wider adoption of preregistered
> multiverse analysis in social science research for checking the
> robustness of empirical findings.

## Overview

For this study, we replicated 6 other studies that employed topic
modeling. For each of them, we re-ran them with varying settings (648 in
totoal) to build a multiverse. Next, we compare the original setting
with the results of varying settings and plot them on various curves

All selected studies make the data and source code publicly available.
Therefore, we could often reuse major parts of the original code, but
sometimes we reimplemented the original code, often in the interest of
improving computing performance or refactoring shared functions into a
common library. The required data files from each study should be in the
`rawdata` directory. All files, except `rawdata/Corona-survey_fill.dta`,
can be downloaded automatically by using `stu rawdata/<filename>`. For
example, to download the text data for Curini and Vignoli (2021) use
`stu rawdata/zip_texts.rar`. Below is a list of the selected studies and
their required datafiles:

- Chan et al. (2022): Data and code is available on
  [OSF](https://osf.io/ycx6j/)
  - Text data: [`rawdata/final_data.RDS`](https://osf.io/3hazf)
- Curini and Vignoli (2021): Data and code is on [Harvard
  Dataverse](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/LAXHS3)
  - Text data:
    [`rawdata/zip_texts.rar`](https://dataverse.harvard.edu/api/access/datafile/4291434)
  - Meta data:
    [`rawdata/meta_table.tab`](https://dataverse.harvard.edu/api/access/datafile/4291441)
  - Lemmatization model:
    [`rawdata/italian-isdt-ud-2.5-191206.udpipe`](https://raw.githubusercontent.com/jwijffels/udpipe.models.ud.2.5/master/inst/udpipe-ud-2.5-191206/italian-isdt-ud-2.5-191206.udpipe)
- Czymara et al. (2020): Data is available upon request via
  [GESIS](https://search.gesis.org/research_data/SDN-10.7802-2034?doi=10.7802/2034),
  source code repository is on
  [Github](https://github.com/czymara/perceiving-COVID19-in-Germany) and
  [OSF](https://osf.io/6s7rp/)
  - Text / survey data:
    [`rawdata/Corona-survey_full.dta`](https://search.gesis.org/research_data/SDN-10.7802-2034?doi=10.7802/2034)
    (You must request it via GESIS BASIS)
  - Stop word list:
    [`rawdata/stopwords-de.txt`](https://raw.githubusercontent.com/czymara/perceiving-COVID19-in-Germany/refs/heads/master/in/stopwords-de.txt)
  - Lemmatization model:
    [`rawdata/rawdata/german-gsd-ud-2.5-191206.udpipe`](https://raw.githubusercontent.com/jwijffels/udpipe.models.ud.2.5/master/inst/udpipe-ud-2.5-191206/german-gsd-ud-2.5-191206.udpipe)
- Jankin et al. (2024): Data available via [Harvard
  Dataverse](https://doi.org/10.7910/DVN/0TJX8Y) (Version 13) and code
  via [PRIO](https://www.prio.org/journals/jpr/replicationdata), see
  entry at section 2025 (62) Issue 4.
  - Text data:
    [`rawdata/ungd_files.RDS`](https://dataverse.harvard.edu/file.xhtml?fileId=11095259&version=13.0)
    Please note that the original file is processed using
    `jankin/00_read.R`. The processed data is made available under CC0
    (Public Domain).
- Takano et al. (2023): Data and code available via
  [OSF](https://osf.io/6ktey/)
  - Text data: [`rawdata/data_pilot_cleaned.csv`](https://osf.io/k6h39)
  - Text data: [`rawdata/data_cleaned.csv`](https://osf.io/ecmt6)
- Tvinnereim and Fløttum (2015): Data and code availble via [Harvard
  Dataverse](https://doi.org/10.7910/DVN/28689)
  - Text data:
    [`rawdata/ncp-stm-data.csv`](https://dataverse.harvard.edu/file.xhtml?persistentId=doi:10.7910/DVN/28689/KO9T0Z&version=1.2)
  - Lemmatization model:
    [`rawdata/norwegian-bokmaal-ud-2.1-20180111.udpipe`](https://github.com/bnosac/udpipe.models.ud/raw/refs/heads/master/models/norwegian-bokmaal-ud-2.1-20180111.udpipe)

The code for each study is in a designated directory (last name of first
author in lowercase letters). The remaining directories of the
repository are:

``` text
├── dev     # additional code for development, testing, and debugging
├── lib     # shared code for all studies and multiverse analysis
├── meta    # additional analysis of the multiverse results
├── results # aggregated results as found in the published study; used for plots
└── plots   # output directory of data visualization
```

# Setup

**Requires R 4.1.0 or newer** We tested our code on R 4.5 (pinned 4.5.0
on Docker) on Ubuntu Linux 22.04.
[`stu`](https://github.com/kunegis/stu) was used to build the project.

There are two ways to manage your R environment so that the correct
packages are installed:

- Using an isolated environment with `renv`. We also use this to manage
  the dependencies for Docker
- Freestyle and use your global environment. All required packages are
  listed in section “Project Dependencies”.

## Environment using renv

### If you are using Windows

> [!NOTE]
>
> Although we expect the R scripts in this codebase to work across all
> platforms, it requires a lot of tooling outside of R (e.g., cURL,
> make) that is readily available on Unix-like systems. Your milage with
> Windows will vary and additional tweaking may be required. In case of
> doubt, we recommend using [Windows Subsystem for
> Linux](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux).

Ensure [Rtools](https://cran.r-project.org/bin/windows/Rtools/) are
installed.

*Protip:* You can install RTools with winget. Open a PowerShell and
enter `winget install rtools`

### Restore the `renv` environment

Ensure `renv` (version \>= 1.1.4, we tested with 1.1.5):

``` bash
R -e 'install.packages("renv")'
```

Then you can activate and restore the environment in R by running:

``` r
renv::activate()
renv::restore()
```

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
pak::pkg_install("<new package dependency>")
renv::snapshot()
```

This should update the `renv.lock` file with the new dependencies.
Please also add the package you added to the section “Project
Dependencies” at the bottom of this readme.

## Docker

> [!WARNING]
>
> Building the docker image can take up to 10 minutes ☠️ ☠️ ☠️

To build the docker image, run this

``` bash
docker compose build
```

To run the pipeline (or part of the pipeline) inside a Docker container,
e.g.,

``` bash
# run the @dockertest target in main.stu
docker compose run --remove-orphans --rm multiverse_tm stu @dockertest
```

``` bash
# run the visualization directly, see the section on reproducing the results
docker compose run --remove-orphans --rm multiverse_tm Rscript chan/04_viz.R
```

## Project Dependencies

R dependencies are listed below [^1]:

``` r
install.packages("pak")
Packages <- c(
    "archive",
    "brms",
    "cowplot",
    "dplyr",
    "effectsize",
    "forcats",
    "fs",
    "furrr",
    "future",
    "ggplot2",
    "ggridges",
    "grateful",
    "grDevices",
    "grid",
    "haven",
    "here",
    "jsonlite",
    "keyATM",
    "lexicon",
    "lme4",
    "lmtest",
    "osfr",
    "purrr",
    "quanteda",
    "readr",
    "renv",
    "rlang",
    "rmarkdown",
    "IshidaMotohiro/RMeCab@2a11093f6a69ee11584aa0e2e8b32a59d1b9f092",
    "sandwich",
    "seededlda",
    "SnowballC",
    "stm",
    "stringr",
    "testthat",
    "tidyr",
    "tools",
    "transport",
    "udpipe"
)

pak::pkg_install(packages)
```

System dependencies on Ubuntu Linux are listed below [^2]:

``` r
apt install -y \
    curl \
    make \
    cmake \
    git \
    libarchive-dev \
    libcurl4-openssl-dev \
    libicu-dev \
    libuv1-dev \
    libxml2-dev \
    libssl-dev \
    pandoc \
    libx11-dev \
    zlib1g-dev \
    mecab \
    libmecab-dev \
    mecab-ipadic-utf8
```

## Options

There are options that one can customize; see `.Rprofile`.

# Reproducing the results

The results are 14 figures in the manuscript. The general procedure is
like this:

``` text
raw data -> intermediate files -> aggregated results -> figures
                               -> figures
```

Intermediate files are document-term matrices, topic model objects, and
Bayesian model objects. While most figures can be generated from
aggregated results, some figures still require the intermediate files.

Because of this, there are three levels of reproduction:

1.  From raw data - reproduce the whole analysis from the datasets of
    the six primary studies, it will generate all the intermediate files
    from the ground up. The intermediate files will be generated with
    some other random seeds.
2.  From intermediate files - reproduce the analysis from our
    intermediate files. Our intermediate files are available as binary
    artefacts on Zenodo: <https://doi.org/10.5281/zenodo.21790776>
    (52GB, please apply for access on Zenodo).
3.  From aggregated results - reproduce the analysis from the aggregated
    results on Github: `results/aggregated`.

> [!WARNING]
>
> If you would like to use our provided intermediate files on Zenodo,
> make sure that you are not using `rlang` version 1.3.0 or above. The
> reason is that [a new hashing
> algorithm](https://github.com/r-lib/rlang/blob/d0e9d81baa937ba7a4cf981dd027229b0229c096/NEWS.md?plain=1#L11-L13)
> was introduced in version 1.3.0 and that makes all existing hashed
> file names invalid. Please use the `renv` or Docker environment
> documented above (which `rlang` was pinned at version 1.1.6).

Level 1 can reproduce all 14 figures. But the analyses will be carried
out with some other random seeds and therefore the figures might look
slightly different. Also, on a computer with six parallel computing
threads, the generation of all intermediate files would take weeks. In
order to generate all intermediate files and some aggregated files, get
all data files (see [Overview](#overview)) and run `stu`.

Level 2 can reproduce all 14 figures *exactly*. With the intermediate
files, some analyses (e.g., Figure 13) still take some time.

Level 3 can only reproduce Figures 1–6, 9, 11, and 14. In other words,
one cannot reproduce Figures 7, 8, 10, 12, 13 only with the aggregated
results on Github.

The figures and the commands to reproduce them are listed below.

| Figure | File name | Level 3 ready? | Command |
|----|----|----|----|
| 1 | `plots/chan_spec.pdf` | Yes | `Rscript chan/04_viz.R` |
| 2 | `plots/curini_spec.pdf` | Yes | `Rscript curini/04_viz.R` |
| 3 | `plots/czymara_spec.pdf` | Yes | `Rscript czymara/04_viz.R` |
| 4 | `plots/takano_spec.pdf` | Yes | `Rscript takano/04_viz.R` |
| 5 | `plots/tvinnereim_spec.pdf` | Yes | `Rscript tvinnereim/04_viz.R` |
| 6 | `plots/curini_spaghetti.pdf` | Yes | `Rscript curini/04_viz.R` |
| 7 | `plots/jankins_spaghetti_full.pdf` | No | `Rscript jankins/04_viz.R` |
| 8 | `plots/jankins_spaghetti_selected.pdf` | No | `Rscript jankins/04_viz.R` |
| 9 | `plots/meta_density.pdf` | Yes | `Rscript meta/modality.R` |
| 10 | `plots/meta_pca.pdf` | No | `Rscript meta/factor.R` |
| 11 | `plots/meta_distribution_max_rho.pdf` | Yes | `Rscript meta/distribution_max_rho.R` |
| 12 | `plots/meta_icc.pdf` | No | `Rscript meta/reliability.R` |
| 13 | `plots/meta_cost.pdf` | No | `Rscript meta/transfer_cost.R; Rscript meta/transfer_cost_vis.R` |
| 14 | `plots/meta_variance_decomposition.pdf` | Yes | `Rscript meta/variance_decomposition.R` |

## Notes about `meta/curinidocker`

In order to run the forensic analysis of Curini and Vignoli (2021) (see
footnote 14 of the paper), Quarto and Docker (preferably in rootness
mode) must be installed. One must have all the original data files from
Curini and Vignoli (2021) in the `rawdata` directory.

``` bash
docker compose -f meta/curinidocker/compose.yaml build
quarto render meta/curinidocker/index.qmd
```

# License

All code is under a [European Union Public Licence 1.2](LICENSE.md) (©
2026 `multiverse_tm` authors), except

- `lib/read_text_base.R` - GPL3
- `lib/lemmatize_words.R` - GPL2
- `lib/plot_spec_curve.R` - GPL3
- `lib/calculate_icc.R` - GPL\>=2
- `lib/check_keywords.R` - GPL3

# References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-chan:2022:WT" class="csl-entry">

Chan, Chung-hong, Jing Zeng, and Mike S. Schäfer. 2022. “Whose Research
Benefits More from Twitter? On Twitter-Worthiness of Communication
Research and Its Role in Reinforcing Disparities of the Field.” *PLOS
ONE* 17 (12): e0278840. <https://doi.org/10.1371/journal.pone.0278840>.

</div>

<div id="ref-curini:2021:CMU" class="csl-entry">

Curini, Luigi, and Valerio Vignoli. 2021. “Committed Moderates and
Uncommitted Extremists: Ideological Leaning and Parties’ Narratives on
Military Interventions in Italy.” *Foreign Policy Analysis* 17 (3).
<https://doi.org/10.1093/fpa/orab016>.

</div>

<div id="ref-czymara:2020:C" class="csl-entry">

Czymara, Christian S., Alexander Langenkamp, and Tomás Cano. 2020.
“Cause for Concerns: Gender Inequality in Experiencing the COVID-19
Lockdown in Germany.” *European Societies* 23 (sup1): S68–81.
<https://doi.org/10.1080/14616696.2020.1808692>.

</div>

<div id="ref-jankin:2024:W" class="csl-entry">

Jankin, Slava, Alexander Baturo, and Niheer Dasandi. 2024. “Words to
Unite Nations: The Complete United Nations General Debate Corpus,
1946–Present.” *Journal of Peace Research*, ahead of print, November.
<https://doi.org/10.1177/00223433241275335>.

</div>

<div id="ref-takano:2023:awe" class="csl-entry">

Takano, Ryota, Akiko Matsuo, and Kazuaki Kawano. 2023. “Development of a
Japanese Version of the Awe Experience Scale (AWE-s): A Structural Topic
Modeling Approach.” *F1000Research* 12: 515.
<https://doi.org/10.12688/f1000research.134275.2>.

</div>

<div id="ref-tvinnereim:2015:E" class="csl-entry">

Tvinnereim, Endre, and Kjersti Fløttum. 2015. “Explaining Topic
Prevalence in Answers to Open-Ended Survey Questions about Climate
Change.” *Nature Climate Change* 5 (8): 744–47.
<https://doi.org/10.1038/nclimate2663>.

</div>

</div>

[^1]: There are also additional dependencies for developers: `jsonlite`,
    `withr`, `clauswilke/colorblindr`, and `quarto`. Please read
    `dev/readme.md`

[^2]: There are also additional dependencies for developers: air, and
    git. Please read `dev/readme.md`
