

# Setup

**Requires R 4.1.0 or newer** We tested our code on R 4.5.1 on Ubuntu
Linux 22.04. [`stu`](https://github.com/kunegis/stu) was used to build
the project.

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

# Studies and Data

All selected studies make the data and source code publicly available.
The required data files from each study should be in the `rawdata`
directory. All files, except `rawdata/Corona-survey_fill.dta`, can be
downloaded automatically by using `stu rawdata/<filename>`. For example,
to download the text data for Curini and Vignoli (2021) use
`stu rawdata/zip_texts.rar`. Below is a list of the selected studies and
their required datafiles:

- Chan, Zeng, and Schäfer (2022): Data and code is available on
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
- Czymara, Langenkamp, and Cano (2020): Data is available upon request
  via
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
- Jankin, Baturo, and Dasandi (2024): Data available via [Harvard
  Dataverse](https://doi.org/10.7910/DVN/0TJX8Y) and code via
  [PRIO](https://www.prio.org/journals/jpr/replicationdata), see entry
  at section 2025 (62) Issue 4.
  - Text data:
    [`rawdata/UNGDC_1946-2024.tar.gz`](https://dataverse.harvard.edu/file.xhtml?fileId=11095259&version=13.0)
  - Meta data:
    [`rawdata/meta_table.tab`](https://dataverse.harvard.edu/api/access/datafile/4291441)
- Takano, Matsuo, and Kawano (2023): Data and code available via
  [OSF](https://osf.io/6ktey/)
  - Text data: [`rawdata/data_pilot_cleaned.csv`](https://osf.io/k6h39)
  - Text data: [`rawdata/data_cleaned.csv`](https://osf.io/ecmt6)
- Tvinnereim and Fløttum (2015): Data and code availble via [Harvard
  Dataverse](https://doi.org/10.7910/DVN/28689)
  - Text data:
    [`rawdata/ncp-stm-data.csv`](https://dataverse.harvard.edu/file.xhtml?persistentId=doi:10.7910/DVN/28689/KO9T0Z&version=1.2)
  - Lemmatization model:
    [`rawdata/norwegian-bokmaal-ud-2.1-20180111.udpipe`](https://github.com/bnosac/udpipe.models.ud/raw/refs/heads/master/models/norwegian-bokmaal-ud-2.1-20180111.udpipe)

# Docker

> [!WARNING]
>
> Building the docker image can take up to 10 minutes ☠️ ☠️ ☠️

The entire analysis can be run with Docker by using

``` bash
docker compose build
docker compose up
```

Note that `docker compose up` currently runs the debug mode of the
`takano` analysis.

# Project Dependencies

R dependencies are listed below [^1]:

``` r
Packages <- c(
    "archive",
    "brms",
    "cowplot",
    "dplyr",
    "fs",
    "furrr",
    "future",
    "ggplot2",
    "ggridges",
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
    "pak",
    "purrr",
    "quanteda",
    "readr",
    "renv",
    "rlang",
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
    libarchive-dev \
    libcurl4-openssl-dev \
    libicu-dev \
    libxml2-dev \
    libssl-dev \
    pandoc \
    libx11-dev \
    zlib1g-dev \
    mecab \
    libmecab-dev \
    mecab-ipadic-utf8
```

# Options

There are options that one can customize; see `.Rprofile`.

# License

All code is under a [European Union Public Licence 1.2](LICENSE.md) (©
2025 `multiverse_tm` authors), except

- [`lib/read_text_base.R`](lib/read_text_base.R) - GPL3
- [`lib/lemmatize_words.R`](lib/lemmatize_words.R) - GPL2
- [`lib/plot_spec_curve.R`](lib/plot_spec_curve.R) - GPL3
- [`lib/calculate_icc.R`](lib/calculate_icc.R) - GPL\>=2
- [`lib/check_keywords.R`](lib/check_keywords.R) - GPL3

# References

<div id="refs" class="references csl-bib-body hanging-indent"
entry-spacing="0">

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
1946–Present.” *Journal of Peace Research*, November.
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
    `withr`, `clauswilke/colorblindr`, and `quarto`

[^2]: There are also additional dependencies for developers: quarto,
    air, and git
