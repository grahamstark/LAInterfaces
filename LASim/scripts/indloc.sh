#!/bin/sh
/bin/cp -f web/index.html web/indexloc.html
/usr/bin/vim -e web/indexloc.html < scripts/indexloc.vim
/bin/cp -f web/index-session.html web/indexloc-session.html
/usr/bin/vim -e web/indexloc-session.html < scripts/indexloc.vim


