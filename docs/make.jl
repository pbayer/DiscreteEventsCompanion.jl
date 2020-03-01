using Documenter

makedocs(
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "DiscreteEventsCompanion.jl",
    authors  = "Paul Bayer",
    pages = [
        "index.md",
        "approach.md",
        "timer.md",
        "performance.md",
        "parallel.md",
        "benchmarks.md"
    ]
)

deploydocs(
    repo   = "github.com/pbayer/DiscreteEventsCompanion.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
    devbranch = "master",
    devurl = "dev",
    versions = ["stable" => "v^", "v#.#", "dev" => "dev"]
)
