FROM ubuntu:disco
MAINTAINER ToDo

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update &&\ 
    apt upgrade -y &&\
    apt install -y git curl time vim gdal-bin gdebi-core &&\
    apt install -y r-base libxml2-dev libssl-dev libcurl4-openssl-dev libgdal-dev libudunits2-dev python3 python3-numpy python3-gdal python-gdal gdal-bin &&\
    echo "install.packages('devtools'); devtools::install_github('IVFL-BOKU/sentinel2'); devtools::install_github('giulange/cubeR')" > /tmp/rpackages.R &&\
    Rscript /tmp/rpackages.R &&\
    rm /tmp/rpackages.R &&\
    cd /root && git clone https://github.com/giulange/cubeR/

# rstudio-server
RUN apt install -y wget units
RUN wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-1.2.5001-amd64.deb && gdebi rstudio-server-1.2.5001-amd64.deb
RUN gdebi -n rstudio-server-1.2.5001-amd64.deb
RUN groupadd -g 3002 rstudio
RUN /usr/sbin/adduser --uid 3002 --gid 3002 --disabled-password --gecos '' rstudio; echo rstudio:@ZVyyBG15muW | chpasswd; ln -s /dati /home/rstudio/dati
EXPOSE 8787
CMD /etc/init.d/rstudio-server start && tail -f /dev/null
