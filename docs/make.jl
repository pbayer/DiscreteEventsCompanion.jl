using Documenter

makedocs(
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "DiscreteEventsCompanion.jl",
    authors  = "Paul Bayer",
    pages = [
        "index.md",
        "clocks.md",
        "events.md",
        "processes.md",
        "random.md",
        "models.md",
        "hybrid.md",
        "examples/examples.md",
        "performance.md",
        "parallel.md",
        "benchmarks.md",
        "internals.md"
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
