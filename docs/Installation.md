## Installation

* Clone this repo.
* Assure you have proper runtime environment - see below.

### Windows

* Install Python 2 or 3 (installers are available at https://www.python.org/downloads/windows/)
* Install Numpy - run `python -m pip install numpy` or `python3 -m pip install numpy` in the console (depending on your Python version)
* Install gdal (version 2.4 or newer) including Python gdal bindings.
  Binary installers are available trough [eo4w](https://trac.osgeo.org/osgeo4w/wiki/WikiStart) and [gisinternals](http://www.gisinternals.com/release.php).
  If you want, you can also compile from source (https://github.com/OSGeo/gdal)
* Install R packages. In R run:
    ```r
    install.packages('devtools')
    devtools::install_github('IVFL-BOKU/sentinel2')
    devtools::install_github('IVFL-BOKU/landsupport')
    ```
### Linux

* Make sure you have Python with numpy and gdal bindings installed.
    * In Ubuntu/Debian run `sudo apt install -y python3 python3-numpy python3-gdal`
    * In Fedora/Centos/RHEL run `sudo yum install -y python3 numpy`
* Install gdal (version 2.4 or newer is required)
    * In Ubuntu/Debian run `sudo apt install -y python-gdal gdal-bin`
    * In Fedora/Centos/RHEL run `sudo yum install -y gdal`
* Install R and libraries required to compile R packages
    * In Ubuntu/Debian run `sudo apt install -y r-base libxml2-dev libssl-dev libcurl4-openssl-dev libgdal-dev libudunits2-dev`
    * In Fedora/Centos/RHEL run `sudo yum install -y R-core libxml2-devel libcurl-devel openssl-devel gdal-devel udunits2-devel`
* Install R packages. In R run:
    ```r
    install.packages('devtools')
    devtools::install_github('IVFL-BOKU/sentinel2')
    devtools::install_github('IVFL-BOKU/landsupport')
    ```

### Docker

* Build a Docker image with `cd {thisRepositoryDirectory} && docker build -t cubeR docker`
* Run the a Docker container `docker run -ti cubeR`.
  The package code is in `/root/landsupport` directory.
  (please consult the [Docker run documentation](https://docs.docker.com/engine/reference/run/) for more advanced settings, e.g. mapping host directories into the container, etc.)

