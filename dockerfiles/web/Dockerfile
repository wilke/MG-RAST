# MG-RAST v3 website

FROM httpd:2.4.12

EXPOSE 80

RUN apt-get update && apt-get install -y \
  git-core \
  libpq-dev \
  make \
  curl \
  perl-modules \
  liburi-perl \
  libwww-perl \
  libfreezethaw-perl \
  libhtml-strip-perl \
  libdbi-perl \
  libdbd-mysql-perl \
  libdbd-pg-perl \
  libhtml-template-perl \
  libtemplate-plugin-number-format-perl \
  libclass-isa-perl \
  libgd-gd2-perl \
  liblist-moreutils-perl \
  libcache-memcached-perl \
  libstatistics-descriptive-perl \
  libcaptcha-recaptcha-perl \
  libxml-simple-perl \
  libdatetime-perl \
  libclass-isa-perl

# v3 website
RUN cd / && \ 
  git clone -b master https://github.com/MG-RAST/MG-RAST.git && \ 
  cd MG-RAST && \
  make && \
  ln -s /config/Conf.pm /MG-RAST/conf/Conf.pm && \
  cd site/CGI && \
  rm -fv api.cgi m5nr.cgi m5nr_rest.cgi

# v4-uploader for v3, only include mgmainv3.html
RUN cd / && git clone --recursive https://github.com/MG-RAST/MG-RASTv4.git && \
  cp -vr /MG-RASTv4/* /MG-RAST/site/CGI/Html/ && \
  rm -vf /MG-RAST/site/CGI/Html/*.html && \
  cp -v /MG-RASTv4/mgmainv3.html /MG-RAST/site/CGI/Html/ && \
  rm -vf /MG-RAST/site/CGI/Html/js/config.js && \
  ln -s /config/config.js /MG-RAST/site/CGI/Html/js/config.js

# pipeline dependencies
RUN apt-get install -y python-dev python-pip && \
  pip install openpyxl==1.8.6 && \
  pip install gspread xlrd lepl && \
  cd / && \
  git clone https://github.com/MG-RAST/pipeline.git && \
  cd pipeline && \
  ln -s /MG-RAST/site/CGI/Tmp temp

# 3rd party dependency: R
RUN mkdir -p /tools && \
  apt-get install -y gcc wget r-base r-cran-nlme r-cran-ecodist r-cran-rcolorbrewer r-cran-xml && \
  echo 'install.packages("matlab", repos = "http://cran.wustl.edu")' | R --no-save && \
  echo 'source("http://bioconductor.org/biocLite.R"); biocLite("pcaMethods"); biocLite("preprocessCore"); biocLite("DESeq")' | R --no-save

# 3rd party dependency: FragGeneScan  
RUN cd /tools && \
  git clone https://github.com/wltrimbl/FGS.git FragGeneScan && \
  cd FragGeneScan && \
  make clean && \
  make fgs

# kegg map data
RUN mkdir -p /data && \
  curl -s "http://shock.metagenomics.anl.gov/node/da268d29-918c-4205-8884-e6f3b175fe58?download" | tar -xvf - -C /data
  

# setup sendmail
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install postfix && \
  cp /usr/share/postfix/main.cf.debian /etc/postfix/main.cf && \
  postconf -e relayhost=[smtp.mcs.anl.gov]

# metazen
RUN cd / && \
  git clone https://github.com/MG-RAST/metazen.git && \
  cd metazen && \
  make

# symlinks for certificates (need to be in daemon home directory) and config.js
RUN ln -s /config/postgresql/ /usr/sbin/.postgresql && \
  rm -f /MG-RAST/site/CGI/Html/js/config.js && \
  ln -s /config/config.js /MG-RAST/site/CGI/Html/js/config.js

# docker run -t -i --name web -v /home/core/mgrast-config/services/web_v3/:/config -p 80:80 httpd:2.4.12 bash
# Start
# bash -c "/bin/chmod 600 /config/postgresql/*; /bin/chown daemon:daemon /config/postgresql/*; /usr/local/apache2/bin/apachectl -f /config/httpd.conf -D FOREGROUND"

