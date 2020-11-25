FROM ubuntu:12.04
SHELL ["/bin/bash", "-i", "-c"]

ARG PYTHON_VERSION=3.9.0
ARG PYINSTALLER_VERSION=4.1

RUN \
    # Print all commands to the terminal as they are executed
    set -x \
    # Update system
    && apt-get update \
    # Install necessary packages
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
    # Clear apt cache
    && apt-get clean \
    # The OpenSSL distribution for Ubuntu 12.04 is outdated, so we will compile a newer version ourselves.
    && cd / \
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
    # Remove directories containing source code for OpenSSL, TCL, and TK
    && cd / \
    && rm -r /openssl-1.0.2u /tcl8.6.10 /tk8.6.10 \
    # Install pyenv
    && echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc \
    && echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc \
    && source ~/.bashrc \
    && curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash \
    && echo 'eval "$(pyenv init -)"' >> ~/.bashrc \
    && source ~/.bashrc \
    # Install the Python version defined by PYTHON_VERSION
    && PATH="$HOME/openssl:$PATH"  CPPFLAGS="-O2 -I$HOME/openssl/include" CFLAGS="-I$HOME/openssl/include/" LDFLAGS="-L$HOME/openssl/lib -Wl,-rpath,$HOME/openssl/lib" LD_LIBRARY_PATH=$HOME/openssl/lib:$LD_LIBRARY_PATH LD_RUN_PATH="$HOME/openssl/lib" CONFIGURE_OPTS="--with-openssl=$HOME/openssl" PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install $PYTHON_VERSION \
    && pyenv global $PYTHON_VERSION \
    && pip install --upgrade pip \
    # Install the PyInstaller version defined by PYINSTALLER_VERSION
    && pip install pyinstaller==$PYINSTALLER_VERSION \
    # Generate the entrypoint script and mark it as executable
    && printf '#!/bin/bash -i\n\nset -e\n. /root/.bashrc\ncd /code\n\nif [ -f requirements.txt ]; then\n    pip install -r requirements.txt\nfi\n\npyinstaller $@' > /entrypoint.sh \
    && chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
