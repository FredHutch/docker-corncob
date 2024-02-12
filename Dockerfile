FROM ubuntu:20.04
MAINTAINER sminot@fredhutch.org

ENV DEBIAN_FRONTEND noninteractive

# Install prerequisites and R
RUN apt update && \
    apt-get -y install --no-install-recommends --no-install-suggests \
    ca-certificates software-properties-common gnupg2 gnupg1 && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/' && \
    ln -fs /usr/share/zoneinfo/Europe/Dublin /etc/localtime && \
    apt-get install -y build-essential wget unzip r-base libssl-dev \
    libxml2-dev libcurl4-openssl-dev libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
    libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev libglpk-dev

# Install devtools
RUN R -e "install.packages('curl', repos = 'http://cran.us.r-project.org'); library(curl)"
RUN R -e "install.packages('httr', repos = 'http://cran.us.r-project.org'); library(httr)"
RUN R -e "install.packages('usethis', repos = 'http://cran.us.r-project.org'); library(usethis)"
RUN R -e "install.packages('ragg', repos = 'http://cran.us.r-project.org'); library(ragg)"
RUN R -e "install.packages('pkgdown', repos = 'http://cran.us.r-project.org'); library(pkgdown)"
RUN R -e "install.packages('devtools', repos = 'http://cran.us.r-project.org'); library(devtools)"
RUN R -e "install.packages('tidyverse', repos = 'http://cran.us.r-project.org'); library(tidyverse)"
RUN R -e "install.packages('vroom', repos = 'http://cran.us.r-project.org'); library(vroom)"
RUN R -e "install.packages('VGAM', repos = 'http://cran.us.r-project.org'); library(VGAM)"

# Install phyloseq
RUN R -e "install.packages('igraph', dependencies=TRUE); library(igraph)"
RUN R -e "install.packages('BiocManager'); BiocManager::install('phyloseq'); library(phyloseq)"

# Install corncob
RUN R -e "library(devtools); devtools::install_github('statdivlab/corncob'); library(corncob)"
