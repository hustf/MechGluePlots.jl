function run_all_tests()
    include("test_plots.jl")
end

# Test file (temporary) placement from Luxor.jl
if get(ENV, "MECHGLUEPLOTS_KEEP_TEST_RESULTS", false) == "true"
    opwd = pwd()
    cd(mktempdir(cleanup=false))
    @info("...Keeping the test plots in: $(pwd())")
    if Sys.iswindows()
        run(`cmd /c explorer .`, wait=false)
    end
    try
        run_all_tests()
    finally
        println("Switch back to original directory ")
        cd(opwd)
    end
    @info("Test plots were saved in: $(pwd())")
else
    mktempdir() do tmpdir
        cd(tmpdir) do
            @info("...Running tests in: $(pwd())")
            @info("but not keeping the results")
            @info("because you didn't do: ENV[\"MECHGLUEPLOTS_KEEP_TEST_RESULTS\"] = \"true\"")
            run_all_tests()
            @info("Test images weren't saved. To see the test images, next time do this before running:")
            @info(" ENV[\"MECHGLUEPLOTS_KEEP_TEST_RESULTS\"] = \"true\"")
        end
    end
end