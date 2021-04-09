include("test_func_defs.jl")

# The most fragile part of this is actually having the recipes applied.
# The recipes easily break due to lacking scope, but without warning.
# If this happens, evaluate the module in global scope, and then
mtds = methods(RecipesBase.apply_recipe);
length(mtds)
@testset verbose = true "Apply_recipe"
    @test length(mtds) > 97

    # function , vector in => vector, vector out
    retval = RecipesBase.apply_recipe(KW(:customcolor => :red), f_r_r, vr)
    @test retval[1].args[1] == vr
    @test retval[1].args[2] == f_r_r.(vr)

    # and now with quanities
    retval = RecipesBase.apply_recipe(KW(:customcolor => :red), f_r_q, vr)
    @test retval[1].args[1] == vr
    @test retval[1].args[2] == f_r_q.(vr)  # Yes, this is not where we replace units

    # Reverse order of arg and foo => same results
    retval = RecipesBase.apply_recipe(KW(:customcolor => :red), vr, f_r_q)
    @test retval[1].args[1] == vr
    @test retval[1].args[2] == f_r_q.(vr)

    # replace vectors with unitless vectors (there are side effects)
    plempty = Plots.plot()
    plotattributes = Dict{Symbol, Any}(:plot_object => plempty, :letter => :y, :label => "f_r_q - 1.0:0.2:3.0")
    retval = RecipesBase.apply_recipe(plotattributes, vr, f_r_q.(vr))
    @test retval[1].args[1] == vr
    @test retval[1].args[2]N == f_r_q.(vr)
    @test haskey(retval[1].plotattributes, :unitinfo)


    # Axis guide
    plotattributes = Dict{Symbol, Any}(:plot_object => plempty, :letter => :y, :yguide => :YAXIS, :label => "f_r_q - 1.0:0.2:3.0")
    retval = RecipesBase.apply_recipe(plotattributes, vr, f_r_q.(vr))
    @test get(retval[1].plotattributes, :yguide, :none) == :YAXIS
end