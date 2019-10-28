FROM ubuntu:disco
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update &&\ 
    apt upgrade -y &&\
    apt install -y git r-base libxml2-dev libssl-dev libcurl4-openssl-dev libgdal-dev libudunits2-dev python3 python3-numpy python3-gdal python-gdal gdal-bin &&\
    echo "install.packages('devtools'); devtools::install_github('IVFL-BOKU/sentinel2'); devtools::install_github('IVFL-BOKU/landsupport')" > /tmp/rpackages.R &&\
    Rscript /tmp/rpackages.R &&\
    rm /tmp/rpackages.R &&\
    cd /root && git clone https://github.com/IVFL-BOKU/landsupport/

