function measure_peak_rss(project, input, minimum_support, implementation)
    cli_script = joinpath(project, "scripts", "cli.jl")
    mktempdir() do directory
        output = joinpath(directory, "frequent.txt")
        rss_log = joinpath(directory, "rss.log")
        if Sys.iswindows()
            wrapper = joinpath(directory, "measure_rss_worker.jl")
            write(wrapper, """
                struct WindowsProcessMemoryCounters
                    cb::UInt32
                    PageFaultCount::UInt32
                    PeakWorkingSetSize::Csize_t
                    WorkingSetSize::Csize_t
                    QuotaPeakPagedPoolUsage::Csize_t
                    QuotaPagedPoolUsage::Csize_t
                    QuotaPeakNonPagedPoolUsage::Csize_t
                    QuotaNonPagedPoolUsage::Csize_t
                    PagefileUsage::Csize_t
                    PeakPagefileUsage::Csize_t
                end
                include(ARGS[1])
                main(ARGS[2:end])
                handle = ccall((:GetCurrentProcess, "kernel32"), Ptr{Cvoid}, ())
                counters = Ref(WindowsProcessMemoryCounters(
                    sizeof(WindowsProcessMemoryCounters), 0, 0, 0, 0, 0, 0, 0, 0, 0))
                ok = ccall((:K32GetProcessMemoryInfo, "kernel32"), Cint,
                    (Ptr{Cvoid}, Ref{WindowsProcessMemoryCounters}, UInt32),
                    handle, counters, sizeof(WindowsProcessMemoryCounters))
                ok != 0 || error("K32GetProcessMemoryInfo failed.")
                println(stderr, "peak_rss_bytes=", counters[].PeakWorkingSetSize)
            """)
            time_command = `$(Base.julia_cmd()) --startup-file=no --threads=1 --project=$project $wrapper $cli_script --input $input --output $output --minsup $minimum_support --implementation $implementation`
            pattern = r"peak_rss_bytes=(\d+)"
            byte_multiplier = 1
        else
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
                error("Peak RSS measurement supports Windows, macOS, and Linux.")
            end
        end
        open(rss_log, "w") do log
            run(pipeline(time_command; stdout = devnull, stderr = log))
        end
        measurement = match(pattern, read(rss_log, String))
        isnothing(measurement) && error("Peak RSS unavailable for $implementation and $input.")
        return parse(Int, measurement.captures[1]) * byte_multiplier
    end
end
