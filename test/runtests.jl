function run_all_tests()
    include("test_plots.jl")
end


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
    # Test file (temporary) placement from Luxor.jl
    mktempdir() do tmpdir
        cd(tmpdir) do
            @info """
                ...Running tests in: $(pwd())
                but not keeping the results
                because you didn't do: ENV[\"MECHGLUEPLOTS_KEEP_TEST_RESULTS\"] = \"true\""
                """
            run_all_tests()
            @info """
            Test images weren't saved. To see the test images, next time do this before running:
            ENV[\"MECHGLUEPLOTS_KEEP_TEST_RESULTS\"] = \"true\"")
            """
        end
    end
end

#=
include("test_func_defs.jl")
function fna(n)
    if Test.get_testset() isa Test.FallbackTestSet
        strip(pref) * " temp " * string(n)
    else
        strip(pref) * Test.get_testset().description * " " *string(n)
    end
end
function _png(n)
    title!(fna(n))
    isfile(fna(n)) && println("Writing over $(fna(n))")
    png(fna(n))
    # uncomment for interactive use:
    #current()
end
_png() = _png("")

tmpdir = raw"C:\Users\frohu_h4g8g6y\AppData\Local\Temp\jl_AQWMSK"
cd(tmpdir)

pref = "no frills"
cd(@__DIR__)
=#