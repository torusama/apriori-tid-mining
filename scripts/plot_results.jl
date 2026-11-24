include(joinpath(@__DIR__, "..", "src", "evaluation", "plot_results.jl"))

function main(arguments = ARGS)
    if length(arguments) != 2
        error("Usage: plot_results.jl benchmark|groceries output_directory")
    end
    kind, directory = arguments
    if kind == "benchmark"
        benchmark_plots(directory)
    elseif kind == "groceries"
        groceries_plots(directory)
    else
        error("Unknown plot type: $kind")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
