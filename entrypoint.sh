#!/bin/bash -i

set -e
. /root/.bashrc
cd /code

if [ -f requirements.txt ]; then
    pip install -r requirements.txt
fi

pyinstaller $@
