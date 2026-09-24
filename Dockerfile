FROM wordpress:4.9

MAINTAINER marco@bakera.de

# stretch/buster are EOL: use archive.debian.org
# (archive signing keys are expired, hence trusted=yes)
RUN rm -f /etc/apt/sources.list.d/buster.list &&\
    echo 'deb [trusted=yes] http://archive.debian.org/debian stretch main' > /etc/apt/sources.list &&\
    echo 'deb [trusted=yes] http://archive.debian.org/debian-security stretch/updates main' >> /etc/apt/sources.list &&\
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive

RUN apt-get update &&\
    apt-get install -y git make sudo gcc build-essential wget\
    # libs for Python 3.6
    libssl-dev zlib1g-dev libncurses5-dev\
    libncursesw5-dev libreadline-dev libsqlite3-dev\
    libgdbm-dev libdb5.3-dev libbz2-dev libexpat1-dev\
    liblzma-dev tk-dev\
    # mysql client for wp-cli (wp db check)
    mysql-client &&\
    apt-get clean

WORKDIR /cscircles
RUN git clone https://github.com/cemc/safeexec.git &&\
    git clone https://github.com/cemc/python3jail.git

WORKDIR /cscircles/safeexec
RUN make

WORKDIR /cscircles/py3
RUN wget https://www.python.org/ftp/python/3.6.1/Python-3.6.1.tar.xz &&\
    tar xf Python-3.6.1.tar.xz
WORKDIR /cscircles/py3/Python-3.6.1
RUN ./configure --prefix=/cscircles/python3jail &&\
    make && make install
# TODO removing working dir afterwards

WORKDIR /cscircles/python3jail
RUN cp /lib64/* lib64 &&\
    cp -r /lib/* lib
RUN mknod -m 0666 ./dev/null c 1 3 &&\
    mknod -m 0666 ./dev/random c 1 8 &&\
    mknod -m 0444 ./dev/urandom c 1 9
#
# create scratch directory for pythonjail
RUN mkdir scratch &&\
    chown root:www-data scratch &&\
    chmod g+w scratch

# CS Circles wp-content (pybox plugin, theme, bundled plugins, lesson_files)
ARG CSCIRCLES_WP_CONTENT_REF=396f40d41860222b4da587aef34636ea05ca2927
RUN git clone https://github.com/cemc/cscircles-wp-content.git /usr/src/cscircles-wp-content &&\
    cd /usr/src/cscircles-wp-content &&\
    git checkout -q ${CSCIRCLES_WP_CONTENT_REF} &&\
    rm -rf .git

# wp-cli
ARG WP_CLI_VERSION=2.10.0
RUN curl -fsSL -o /usr/local/bin/wp \
      https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar &&\
    chmod +x /usr/local/bin/wp &&\
    printf 'apache_modules:\n  - mod_rewrite\n' > /etc/wp-cli.yml
ENV WP_CLI_CONFIG_PATH=/etc/wp-cli.yml

COPY cscircles-setup.sh /usr/local/bin/cscircles-setup
RUN chmod +x /usr/local/bin/cscircles-setup

VOLUME /var/www/html

WORKDIR /var/www/html

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]

EXPOSE 80
