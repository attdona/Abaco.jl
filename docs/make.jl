using Abaco
using Documenter

DocMeta.setdocmeta!(Abaco, :DocTestSetup, :(using Abaco); recursive=true)

makedocs(;
    modules=[Abaco],
    authors="Attilio <attilio.dona@telecomitalia.it> and contributors",
    repo="https://github.com/attdona/Abaco.jl/blob/{commit}{path}#{line}",
    sitename="Abaco.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://attdona.github.io/Abaco.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/attdona/Abaco.jl",
    devbranch = "main"
)
