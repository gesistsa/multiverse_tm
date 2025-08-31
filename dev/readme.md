# Development README

The following assumes you are using a Ubuntu 22.04 environment.

# Setup

Please install `quarto` (for rendering of the README), `air` (for formatting R code automatically), and `stu` (for automation)

```sh
QUARTO_VERION=1.6.40
curl -q -o /tmp/quarto_amd64.deb -L https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb
sudo dpkg -i /tmp/quarto_amd64.deb 
```

```sh
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/posit-dev/air/releases/download/0.7.1/air-installer.sh | sh
```

```sh
STU_VERSION="2.7.85"
curl -q -o /tmp/stu_amd64.deb -L https://github.com/kunegis/stu/releases/download/${STU_VERSION}/stu_amd64.deb \
  && sudo dpkg -i /tmp/stu_amd64.deb \
  && rm /tmp/stu_amd64.deb
```

## `renv` "dev" profile

On top of the "default" `renv` profile documented in the main `README`, there is also a "dev" profile for development, mostly for running unit tests and rendering of `README`. You can launch the "dev" profile by setting the environment variable `RENV_PROFILE=dev`, i.e.

```sh
env RENV_PROFILE=dev R
```

If it complains about lack of `here` and/or the project is in a inconsistent state, run:

```r
renv::store()
```

Usually, you don't need to launch this profile explicitly. Please use the targets defined in `main.stu`

```sh
## unit testing
stu @test
```

```sh
## rendering
stu @rmd
```

The repercussion is that if the "default" `renv` profile changes (e.g., needing more R packages), you also needs to update the "dev" profile.

# Rendering `README`

The readme has a file extension of `.rmd`, but it's actually a Quarto document. Updating it requires some additional steps as documented in `main.stu`. Concretely, one has to cache all R and system requirements in `dev/requirements.json`. This file will be used in the rendering of `readme.rmd` and updating `Dockerfile`.

It is in general not recommended to do that manually. Please use `stu @rmd`

### Even better: Use the precommit hook

If possible, please use the precommit hook to automate even more tasks. You can deploy the precommit hook in your local git repository with `stu @deploy-hook`. The source of the hook is `dev/precommit.sh`.

It does two things:

* When either `readme.rmd` or `renv.lock` are changed and committed, it runs `stu @rmd` and add the newly rendered `readme.md` and `Dockerfile` automatically before actually committing.
* When there are `.R` files changed, it runs `air` to format them first before committing

