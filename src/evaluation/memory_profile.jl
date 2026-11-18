function measure_peak_rss(project, input, minimum_support, implementation)
    cli_script = joinpath(project, "scripts", "cli.jl")
    mktempdir() do directory
        output = joinpath(directory, "frequent.txt")
        rss_log = joinpath(directory, "rss.log")
        command = `$(Base.julia_cmd()) --startup-file=no --threads=1 --project=$project $cli_script --input $input --output $output --minsup $minimum_support --implementation $implementation`
        if Sys.isapple()
            time_command = `/usr/bin/time -l $command`
            pattern = r"(\d+)\s+maximum resident set size"
            byte_multiplier = 1
        elseif Sys.islinux()
            time_command = `/usr/bin/time -f "peak_rss_kib=%M" $command`
            pattern = r"peak_rss_kib=(\d+)"
            byte_multiplier = 1024
        else
            error("Peak RSS measurement supports macOS and Linux.")
        end
        open(rss_log, "w") do log
            run(pipeline(time_command; stdout = devnull, stderr = log))
        end
        measurement = match(pattern, read(rss_log, String))
        isnothing(measurement) && error("Peak RSS unavailable for $implementation and $input.")
        return parse(Int, measurement.captures[1]) * byte_multiplier
    end
end
