FROM ubuntu:latest

MAINTAINER SachiO

RUN rm -rf /usr/sbin/policy-rc.d 
ADD policy-rc.d /usr/sbin/policy-rc.d
RUN chmod +x /usr/sbin/policy-rc.d

ADD  bitzenyd /bin/bitzenyd
RUN chmod +x /bin/bitzenyd

RUN mkdir /root/.bitzenyd \
    && mkdir /root/.bitzenyd/testnet

ADD bitzeny.conf /root/.bitzent/bizeny.conf
ADD wallet.dat /root/.bitzeny/testnet/wallet.dat

ENV APACHE_RUN_USER="www-data" \
    APACHE_RUN_GROUP="www-data" \
    APACHE_PID_FILE="/var/run/apache2.pid" \
    APACHE_RUN_DIR="/var/run/apache2" \
    APACHE_LOCK_DIR="/var/lock/apache2" \
    APACHE_LOG_DIR="/var/log/apache2" \
    APACHE_USER_UID="0" \
    DEBIAN_FRONTEND="noninteractive"

RUN apt-get update -qq \
    && apt-get install -y apt-utils perl --no-install-recommends
    
RUN apt-get install -qqy --force-yes \
    build-essential \
    apache2 \
    cron \
#    libapache2-mod-php \
    supervisor \
    curl \
    openssh-server \
    libboost-all-dev \
    libcurl4-openssl-dev \
    libdb5.3-dev \
    libdb5.3++-dev \
    mysql-server \
    git

RUN apt-get -y update \
    && apt-get -y upgrade \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C \
    # && gpg -a --export 4F4EA0AAE5267A6C \
    # && apt-key add - \
    && apt-get install -y python3.6 \
    && rm /usr/bin/python \
    && ln -s /usr/bin/python3.6 /usr/bin/python

RUN wget https://bootstrap.pypa.io/get-pip.py \
    && python get-pip.py
RUN apt-get install -y python3-pip \
    && ln -s /usr/bin/pip3 /usr/bin/pip

RUN apt-get -y purge php* \
    && apt -y autoremove \
    && apt autoclean \
    && apt-get -y install software-properties-common \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get -y install php5.6 \
    && apt-get -y install php5.6 php5.6-cgi libapache2-mod-php5.6 php5.6-common php-pear
#     && apt-get install -y  libapache2-mod-php5

RUN pip -V
RUN rm -rf /etc/apache2/apache2.conf

ADD apache2.conf /etc/apache2/apache2.conf
ADD apache_default /etc/apache2/sites-available/000-default.conf

RUN cd /var/www \
    && git clone git://github.com/MPOS/php-mpos.git mpos \
    && cd mpos \
#    && python -V \
    && git checkout master \
    && chown -R www-data templates/compile templates/cache 
RUN cd /root \
#    && python -V \
    && git clone https://github.com/ahmedbodi/stratum-mining.git \
    && cd /root/stratum-mining \
#    && python -V \ 
    && git submodule init \
    && git submodule update \
    && cd /root/stratum-mining/externals/litecoin_scrypt \
    && apt-get install -y python3.6-dev \
    && export CPATH=$CPATH:/usr/include/python3.6/ \
#    && printenv \
#    && python -V \
    && ls /root/stratum-mining/externals/litecoin_scrypt -l \
    && python setup.py install \
    && mkdir /root/stratum-mining/log

ADD config.py /root/stratum-mining/conf/config.py
ADD global.inc.php /var/www/mpos/include/config/global.inc.php
ADD start-apache2.sh /start-apache2.sh
ADD start-mysqld.sh /start-mysqld.sh
ADD start-cron.sh /start-cron.sh
ADD start-bitzenyd.sh /start-bitzenyd.sh
ADD start-stratum.sh /start-stratum.sh
ADD start-memcached.sh /start-memcached.sh

ADD run.sh /run.sh
RUN chmod 755 /*.sh

RUN a2enmod rewrite \
    && service apache2 restart

ENV PHP_UPLOAD_MAX_FILESIZE="10M" \
    PHP_POST_MAX_SIZE="10M"

RUN echo 'root:root' |chpasswd \
    && sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config \
    && ls -l /usr/local/lib/python3.6/dist-packages
#    && sed -ri 's/from autobahn.websocket import WebSocketServerProtocol, WebSocketServerFactory/from autobahn.twisted.websocket import WebSocketServerProtocol, WebSocketServerFactory/g' /usr/local/lib/python2.7/dist-packages/stratum-0.2.13-py2.7.egg/stratum/websocket_transport.py
ADD supervisord-openssh-server.conf /etc/supervisor/conf.d/supervisord-openssh-server.conf

EXPOSE 80 443 3306 22 3333
CMD ["/run.sh"]