using Documenter

const PAGES = Any[
    "Home" => "index.md",
    "Manual" => [
        "Discrete Event Systems" => "DES.md",
        "Clocks" => "clocks.md",
        "Actions" => "actions.md",
        "Sampling" => "sampling.md",
        "Events" => "events.md",
        "Activities" => "activities.md",
        "Processes" => "processes.md",
        "Randomness" => "random.md",
        "State Machines" => "automata.md",
        "Actors" => "actors.md",
        "Models" => "models.md",
    ],
    "Examples" => [
        "Overview" => "examples/examples.md",
        "Introductory" => [
            "Single Server" => "examples/singleserver.md",
            "Table Tennis" => "examples/tabletennis.md"
        ],
        "M/M/c Queue" => [
            "M/M/c Activities" => "examples/queue_mmc_act.md",
            "M/M/c Processes" => "examples/queue_mmc_srv.md",
            "M/M/c State Machines" => "examples/queue_mmc_sm.md",
            "M/M/c Actors" => "examples/queue_mmc_actor.md",
            "M/M/c Interrupted Processes" => "examples/queue_mmc_srv_fail.md"
        ],
        "Multi-Threading (Experimental)" => [
            "Assembly Line" => "examples/assy_thrd.md"
        ],
        "Other" => [
            "House Heating" => "examples/house_heating/house_heating.md",
            "Post Office" => "examples/postoffice/postoffice.md",
            "Goldratt's Dice Game" => "examples/dicegame/dicegame.md"    
        ]
    ],
    "Performance" => "performance.md",
    "Parallel Simulation" => "parallel.md",
    "Benchmarks" => "benchmarks.md",
    "Diagnosis" => "diag.md",
    "Internals" => "internals.md",
]

makedocs(
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename = "DiscreteEventsCompanion.jl",
    authors  = "Paul Bayer",
    pages = PAGES
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
