using OntologyTrees
using Documenter

DocMeta.setdocmeta!(OntologyTrees, :DocTestSetup, :(using OntologyTrees); recursive=true)

makedocs(;
    modules=[OntologyTrees],
    authors="Chris Damour",
    sitename="OntologyTrees.jl",
    format=Documenter.HTML(;
        canonical="https://damourChris.github.io/OntologyTrees.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/damourChris/OntologyTrees.jl",
    devbranch="main",
)
