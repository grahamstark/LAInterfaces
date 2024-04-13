#!/bin/sh

/bin/cp -f web/index.html web/indexloc.html

/usr/bin/vim -e web/indexloc.html < scripts/indexloc.vim

