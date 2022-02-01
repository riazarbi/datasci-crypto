FROM riazarbi/datasci-gui-minimal:20220201140358

LABEL authors="Riaz Arbi"

# Be explicit about user
# This is because we switch users during this build and it can get confusing
USER root

RUN pip3 install luno-python
 
# For arrow to install bindings
ENV LIBARROW_DOWNLOAD=true
ENV LIBARROW_MINIMAL=false

# Install R packages
RUN DEBIAN_FRONTEND=noninteractive \ 
    apt-get update \
 && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y  \
    libsodium-dev \
    libmariadb-dev \
    libmariadbclient-dev  \
    libsecret-1-dev \
    libpq-dev \
 && rm -rf /tmp/*

RUN install2.r --skipinstalled --error  --ncpus 3 --deps TRUE -l $R_LIBS_SITE   \
    gt dplyr arrow blastula readr prophet forecast
    
# Run as NB_USER ============================================================

USER $NB_USER
