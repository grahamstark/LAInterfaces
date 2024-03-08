using LAInterfaces
using Documenter

DocMeta.setdocmeta!(LAInterfaces, :DocTestSetup, :(using LAInterfaces); recursive=true)

makedocs(;
    modules=[LAInterfaces],
    authors="Graham Stark",
    repo="https://github.com/grahamstark/LAInterfaces.jl/blob/{commit}{path}#{line}",
    sitename="LAInterfaces.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://grahamstark.github.io/LAInterfaces.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/grahamstark/LAInterfaces.jl",
    devbranch="main",
)
