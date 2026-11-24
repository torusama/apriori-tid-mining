include(joinpath(@__DIR__, "scripts", "cli.jl"))

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
