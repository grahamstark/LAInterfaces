"""
Use like: 

    vim -e [file] < scripts/indexloc.vim

"""
%s/\/lasim\//\//g
:write
:quit