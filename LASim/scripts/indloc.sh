#!/bin/sh
/bin/cp -f web/index-apache.html web/index.html
/usr/bin/vim -e web/index.html < scripts/indexloc.vim
