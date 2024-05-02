julia --color=yes --depwarn=no --project=@. -q -i -t auto -- "%~dp0..\bootstrap.jl" -s=true %*
