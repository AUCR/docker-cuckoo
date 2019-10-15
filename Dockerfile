FROM alpine AS yara

ENV YARA_VERSION 3.10.0

RUN apk add --no-cache \
    openssl \
    file \
    jansson \
    bison \
    python \
    tini \
    su-exec

RUN apk add --no-cache -t .build-deps \
    py-setuptools \
    openssl-dev \
    jansson-dev \
    python-dev \
    build-base \
    libc-dev \
    file-dev \
    automake \
    autoconf \
    libtool \
    flex \
    git \
  && set -x \
  && echo "Install Yara from source..." \
  && cd /tmp/ \
  && git clone --recursive --branch v$YARA_VERSION https://github.com/VirusTotal/yara.git \
  && cd /tmp/yara \
  && ./bootstrap.sh \
  && sync \
  && ./configure --with-crypto \
                 --enable-magic \
                 --enable-cuckoo \
                 --enable-dotnet \
  && make \
  && make install \
  && echo "Install yara-python..." \
  && cd /tmp/ \
  && git clone --recursive --branch v$YARA_VERSION https://github.com/VirusTotal/yara-python \
  && cd yara-python \
  && python setup.py build --dynamic-linking \
  && python setup.py install \
  && rm -rf /tmp/* \
  && apk del --purge .build-deps

VOLUME ["/malware"]
VOLUME ["/rules"]

WORKDIR /malware

ENTRYPOINT ["su-exec","nobody","/sbin/tini","--","yara"]

FROM yara AS volatility

ENV VOL_VERSION 2.6

# Install Volatility Dependancies
RUN apk add --no-cache ca-certificates zlib py-pillow py-crypto py-lxml py-setuptools
RUN apk add --no-cache -t .build-deps \
    openssl-dev \
    python-dev \
    build-base \
    zlib-dev \
    libc-dev \
    jpeg-dev \
    automake \
    autoconf \
    py-pip \
    git \
  && export PIP_NO_CACHE_DIR=off \
  && export PIP_DISABLE_PIP_VERSION_CHECK=on \
  && pip install --upgrade pip wheel \
  && pip install simplejson \
    construct \
    openpyxl \
    haystack \
    distorm3 \
    colorama \
    ipython \
    pycoin \
    pytz \
  && cd /tmp \
  && echo "===> Installing Volatility from source..." \
  && git clone --recursive --branch $VOL_VERSION https://github.com/volatilityfoundation/volatility.git \
  && cd volatility \
  && python setup.py build install \
  && rm -rf /tmp/* \
  && apk del --purge .build-deps

VOLUME ["/data"]
VOLUME ["/plugins"]

WORKDIR /data

ENTRYPOINT ["su-exec","nobody","/sbin/tini","--","vol.py"]
CMD ["-h"]

FROM volatility AS suricata

RUN apk update

RUN apk add --no-cache \
    suricata

FROM suricata AS sflock

ENV LIBRARY_PATH=/lib:/usr/lib

RUN apk add --no-cache \
    zlib \
    py-pillow \
    py-crypto

RUN apk add --no-cache -t .build-deps \
    build-base \
    openssl-dev \
    libffi-dev \
    python-dev \
    zlib-dev \
    jpeg-dev \
    py-pip \
    git \
  && echo "Install sflock..." \
  && cd /tmp/ \
  && git clone --recursive https://github.com/wroersma/sflock.git \
  && cd sflock \
  && python setup.py install \
  && rm -rf /tmp/* \
  && apk del --purge .build-deps

FROM sflock AS ssdeep

ENV SSDEEP 2.14.1

RUN apk add --no-cache \
    zlib \
    py-pillow \
    py-crypto

RUN apk add --no-cache -t .build-deps \
    build-base \
    python-dev \
    zlib-dev \
    jpeg-dev \
    py-pip \
    git \
  && cd /tmp \
  && echo "===> Install ssdeep..." \
  && wget -O /tmp/$SSDEEP.tar.gz https://github.com/ssdeep-project/ssdeep/releases/download/release-$SSDEEP/ssdeep-$SSDEEP.tar.gz \
  && cd /tmp \
  && tar zxvf $SSDEEP.tar.gz \
  && cd ssdeep-$SSDEEP \
  && ./configure \
  && make \
  && make install \
  && echo "===> Install pydeep..." \
  && cd /tmp \
  && git clone https://github.com/kbandla/pydeep.git \
  && cd pydeep \
  && python setup.py build \
  && python setup.py install

FROM ssdeep AS cuckoo

ENV CUCKOO_CWD /cuckoo

RUN apk update \
  && apk add --update tcpdump

RUN apk add --no-cache ca-certificates \
    zlib \
    py-pillow \
    py-crypto \
    py-lxml \
    openssl \
    file \
    jansson \
    bison \
    python \
    tini \
    yaml \
    su-exec \
    py-chardet \
    py-libvirt \
    curl \
    libpq \
    pcre-dev \
    cairo \
    cairo-dev \
    pango \
    gdk-pixbuf \
    libconfig \
    iptables
RUN apk add postgresql-dev \
    swig \
    build-base \
    zlib-dev \
    libc-dev \
    jpeg-dev \
    automake \
    autoconf \
    py-pip \
    git \
    py-setuptools \
    jansson-dev \
    python-dev \
    build-base \
    file-dev \
    libtool \
    libxml2-dev \
    flex \
    libxslt-dev \
    libffi-dev \
    libstdc++ \
    file-dev \
    linux-headers \
    python3-dev \
    libffi-dev \
    yaml-dev \
    libpcap-dev \
    libpcap-doc \
    libmagic \
    gcc \
    g++ \
    libconfig-dev

RUN apk add --no-cache -t .build-deps \
    swig \
    postgresql-dev \
    libressl-dev \
    build-base \
    zlib-dev \
    libc-dev \
    jpeg-dev \
    automake \
    autoconf \
    py-pip \
    git \
    py-setuptools \
    jansson-dev \
    python-dev \
    build-base \
    file-dev \
    libtool \
    libxml2-dev \
    flex \
    libxslt-dev \
    libffi-dev \
    libstdc++ \
    file-dev \
    linux-headers \
    python3-dev \
    libffi-dev \
    yaml-dev \
    libpcap-dev \
    libpcap-doc \
    libmagic \
    gcc \
    g++ \
    libconfig-dev  \
  && export PIP_NO_CACHE_DIR=off \
  && export PIP_DISABLE_PIP_VERSION_CHECK=on \
  && pip install --upgrade html5lib==1.0b8 \
  && pip install \
    psycopg2 \
    simplejson \
    construct \
    openpyxl \
    haystack \
    distorm3 \
    colorama \
    ipython \
    pycoin \
    pytz \
    validators \
    unidecode \
    pyminizip==0.2.3 \
    m2crypto \
    weasyprint==0.36 \
    wheel \
    setuptools \
  && echo "===> Install Cuckoo Sandbox...." \
  && mkdir /cuckoo \
  && adduser -D -h /cuckoo cuckoo \
  && export PIP_NO_CACHE_DIR=off \
  && export PIP_DISABLE_PIP_VERSION_CHECK=on

COPY requirements.txt /tmp
RUN cd /tmp \
  && pip install -r requirements.txt

FROM cuckoo

COPY cuckoo/ /tmp/cuckoo/
RUN cd /tmp/cuckoo/ \
  && python stuff/monitor.py \
  && python setup.py sdist install \
  && LDFLAGS=-L/lib pip install . \
  && cd /cuckoo \
  && cuckoo \
  && cuckoo --cwd /cuckoo community \
  && cd /tmp \
  && apk del --purge .build-deps \
  && cd /tmp \
  && rm -rf /tmp/*



COPY conf /cuckoo/conf
COPY 2.0/update_conf.py /update_conf.py
COPY 2.0/docker-entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh
RUN chmod a+x /update_conf.py
COPY 192.168.40.83.pem /cuckoo/
WORKDIR /cuckoo/


VOLUME ["/cuckoo/conf"]

EXPOSE 1337 31337
ENTRYPOINT ["/entrypoint.sh"]
CMD ["--help"]
