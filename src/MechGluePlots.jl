"Units in plots, for MechanicalUnits.jl>Unitful.jl"
module MechGluePlots
import Unitfu
import Unitfu: AbstractQuantity, Quantity, unit, ustrip, ∙
import Plots
import Plots: expand_extrema!
using RecipesBase

# In RecipesPipeline, this is called prior to recipes on single axis vectors.
# Output is modified:
# Replace the function with a vector of values, and let the rest be done further down the pipeline.
# @recipe function f(foo::F, x::T) where {F<:Function, T <: AbstractArray{<:Union{Missing,<:Quantity}}}
@recipe function f(foo::F, x::T) where {F<:Function, T <: AbstractArray}
    qval = foo.(x)
    println(":debug1 foo, x")
    return x, qval # Note the swap. For series with values, the ordinat is placed second.
end

@recipe function f(x::T, foo::F) where {F<:Function, T <: AbstractArray}
    qval = foo.(x)
    println(":debug1.5 x, foo")
    # Without recipes, plot(0:10, sin) and plot(sin, 0:10) produce the same plot, sin on y. Same here:
    return x, qval
end

function relevant_key(plotattributes)
    if RecipesBase.is_explicit(plotattributes, :letter)
        letter = plotattributes[:letter]
        Symbol(letter, :guide)
    else
        :guide
    end
end



# apply_recipe args: Any[:(::Type{T}), :(x::T)]
@recipe function f(::Type{T}, x::T) where T <: AbstractArray{<:Union{Missing,<:Quantity}}
    # while plotting, modify a vector of quantities to unitless,
    # but push the unit info to the relevant place.
    printstyled(color=:green, ":debug2 vq \t")
    printstyled(plotattributes, "\n", color=:green)

    u = unit(eltype(x))
    relevantkey = relevant_key(plotattributes)
    plot_ob = get(plotattributes, :plot_object, nothing)
    nprocessedplots = isnothing(plot_ob) ? 0 : plot_ob.n
    nseries = isnothing(plot_ob) ? 0 : length(plot_ob.series_list)
    preguide = string(get(plotattributes, relevantkey, nothing))
    units_at_axes = Bool(get(plotattributes, :units_at_axes, true))
    @show nprocessedplots, nseries
    if units_at_axes && preguide == "nothing" && nprocessedplots == 0 && nseries == 0
        # Add a guide with units to the axis
        su = "[" * string(u) * "]"
        # Store the unit information where we can more easily find it.
        # The information is lost after all series have passed through the pipeline.
        Symbol(relevantkey, :_has_units) --> su, :quiet
        @info "add guide $su "
        guide --> su
    else
        letter = plotattributes[:letter]
        attnam = Symbol(letter, :formatter)
        @info "-------------add formatter , preguide = $preguide, attnam = $attnam"
        Symbol(letter, :formatter) --> x-> string(eltype(T)(x))
    end
    qvals = ustrip(x ./ u)
    return qvals
end


#=
@userplot struct VS2{T<:Vector{Tuple{AbstractVector, AbstractVector}}}
    args::T
end



#@recipe function f(::Type{T}, val::C) where C<:(AbstractVector{T} where T<:(Tuple))
#@recipe function f(::Type{T}, x::AbstractVector{T}) where {T <: Tuple}
#@recipe function f(::Type{T}, x::T) where {T <: VS2}
@recipe function f(x::VS2)

    println("debug tuple---------------------------------")
    return x.args
end
=#
# TODO add precompile directives for Float64 and the most common unit




end