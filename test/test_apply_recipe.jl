include("test_func_defs.jl")


# The most fragile part of this is actually having the recipes applied.
# The recipes easily break due to lacking scope, but without warning.
# If this happens, evaluate the module in global scope, and then
mtds = methods(RecipesBase.apply_recipe);
length(mtds)

@test length(mtds) > 93
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
@test haskey(retval[1].plotattributes, :yguide)


# Axis guide
plotattributes = Dict{Symbol, Any}(:plot_object => plempty, :letter => :y, :yguide => :YAXIS, :label => "f_r_q - 1.0:0.2:3.0")
retval = RecipesBase.apply_recipe(plotattributes, vr, f_r_q.(vr))
get(retval[1].plotattributes, :yguide, :none) == :YAXIS
retval[1].plotattributes
@test haskey(retval[1].plotattributes, :yformatter)
strfirsttick = get(retval[1].plotattributes, :yformatter, Float64)(f_r_q(vr[1])) 
@test strfirsttick == "1.2013785099635535e-15N"
retval[1].args[2]N == f_r_q.(vr)

# Force-trigger no unit axis guide
plotattributes = Dict{Symbol, Any}(:plot_object => plempty, :letter => :y, :units_at_axes => :false)
retval = RecipesBase.apply_recipe(plotattributes, vr, f_r_q.(vr))
get(retval[1].plotattributes, :yguide, :none) == :none

#=
# Vector of tuples
plotattributes = Dict{Symbol, Any}(:plot_object => plempty)
tuparg = [(s1x∙m, s1y∙m), (s2x∙s, s2y∙s), (s1x, s1y)]
eltype(tuparg)
S2 = Tuple{AbstractArray{S, N}, AbstractArray{T, N}} where {S, T, N}
typeof.(tuparg) .<:S2
foo(x::S2) = true
foo(x) = false
@test sum(foo.(tuparg)) == 3
@test foo(tuparg) == false
VS2 = Vector{<:S2}
tuparg isa VS2
foo(tuparg::VS2) = true
@test foo(tuparg) == true
tfo(::Type{T}, x::T) where {T <: VS2} = true
tfo(x::T) where T = tfo(T, x)
@test tfo(tuparg) == true
RecipesBase.debug(true)
firstpass = RecipesBase.apply_recipe(plotattributes, tuparg)

tuparg = [(s1x, s1y), (s2x, s2y), (s1x, s1y)]
plot(tuparg)

s1x = [1.0,2,3]
s1y = [1.0,2,3]
s2x = [1.0,2,3]
s2y = [1.0,2,2]

tuparg = [(s1x, s1y), (s2x, s2y), (s1x, s1y)]
plot(tuparg)
=#