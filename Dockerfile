FROM wordpress:4.9

MAINTAINER marco@bakera.de

RUN apt-get update &&\
    apt-get install -y git make sudo gcc build-essential wget\
    # libs for Python 3.6
    libssl-dev zlib1g-dev libncurses5-dev\
    libncursesw5-dev libreadline-dev libsqlite3-dev\
    libgdbm-dev libdb5.3-dev libbz2-dev libexpat1-dev\
    liblzma-dev tk-dev &&\
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

VOLUME /var/www/html

WORKDIR /var/www/html

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]

EXPOSE 80
