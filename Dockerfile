FROM ubuntu:12.04
SHELL ["/bin/bash", "-i", "-c"]

ARG PYTHON_VERSION=3.9.0
ARG PYINSTALLER_VERSION=4.1

COPY entrypoint.sh /entrypoint.sh

RUN \
    set -x \
    # update system
    && apt-get update \
    # install requirements
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        wget \
        git \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        zlib1g-dev \
        libffi-dev \
        libgdbm-dev \
        libgdbm3 \
        uuid-dev \
        upx \
        libx11-dev \
        libxft-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
    # required because openSSL on Ubuntu 12.04 and 14.04 run out of support versions of OpenSSL
    && mkdir openssl \
    && cd openssl \
    # latest version, there won't be anything newer for this
    && wget https://www.openssl.org/source/openssl-1.0.2u.tar.gz \
    && tar -xzvf openssl-1.0.2u.tar.gz \
    && rm openssl-1.0.2u.tar.gz \
    && cd openssl-1.0.2u \
    && ./config --prefix=$HOME/openssl --openssldir=$HOME/openssl shared zlib \
    && make \
    && make install \
    # The TCL and TK distributions for Ubuntu 12.04 are outdated, so we will compile newer versions ourselves.
    && cd / \
    && wget https://netactuate.dl.sourceforge.net/project/tcl/Tcl/8.6.10/tcl8.6.10-src.tar.gz?viasf=1 -O tcl8.6.10-src.tar.gz \
    && wget https://iweb.dl.sourceforge.net/project/tcl/Tcl/8.6.10/tk8.6.10-src.tar.gz?viasf=1 -O tk8.6.10-src.tar.gz \
    && tar -xzvf tcl8.6.10-src.tar.gz \
    && tar -xzvf tk8.6.10-src.tar.gz \
    && rm tcl8.6.10-src.tar.gz \
    && rm tk8.6.10-src.tar.gz \
    && cd /tcl8.6.10/unix \
    && ./configure --prefix=/usr \
    && make \
    && make install \
    && cd /tk8.6.10/unix \
    && ./configure --prefix=/usr \
    && make \
    && make install \
    # install pyenv
    && echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc \
    && echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc \
    && source ~/.bashrc \
    && curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash \
    && echo 'eval "$(pyenv init -)"' >> ~/.bashrc \
    && source ~/.bashrc \
    # install python
    && PATH="$HOME/openssl:$PATH"  CPPFLAGS="-O2 -I$HOME/openssl/include" CFLAGS="-I$HOME/openssl/include/" LDFLAGS="-L$HOME/openssl/lib -Wl,-rpath,$HOME/openssl/lib" LD_LIBRARY_PATH=$HOME/openssl/lib:$LD_LIBRARY_PATH LD_RUN_PATH="$HOME/openssl/lib" CONFIGURE_OPTS="--with-openssl=$HOME/openssl" PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install $PYTHON_VERSION \
    && pyenv global $PYTHON_VERSION \
    && pip install --upgrade pip \
    # install pyinstaller
    && pip install pyinstaller==$PYINSTALLER_VERSION \
    && chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
