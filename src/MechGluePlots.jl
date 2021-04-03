"Units in plots, for MechanicalUnits.jl>Unitful.jl"
module MechGluePlots
import Unitfu
import Unitfu: AbstractQuantity, Quantity, unit, ustrip, ∙, numtype
import Plots
import Plots: default
import Base: show, get
using RecipesBase
import RecipesBase._debug_recipes
struct SeriesUnitInfo
    serno
    unit
    label
    relevant_axis_guide
    letter
    sertyp
end

include("internal_functions.jl")
# In RecipesPipeline, this is called prior to recipes on single axis vectors.
# Replace the function with a vector of values, and let the rest be done further down the pipeline.
# @recipe function f(foo::F, x::T) where {F<:Function, T <: AbstractArray{<:Union{Missing,<:Quantity}}}
@recipe function f(foo::F, x::T) where {F<:Function, T <: AbstractArray}
    _debug_recipes[1] && printstyled(color=:red, ":MechGluePlots foo::F, x::T) where {F<:Function, T <: AbstractArray} \n")
    x, foo.(x) # Note the swap. For series with values, the ordinat is placed second.
    # TODO test multiple columns
end

@recipe function f(x::T, foo::F) where {F<:Function, T <: AbstractArray}
    _debug_recipes[1] && printstyled(color=:red, ":MechGluePlots x::T, foo::F) where {F<:Function, T <: AbstractArray} \n")
    # Without recipes, plot(0:10, sin) and plot(sin, 0:10) produce the same plot, sin on y. Same here:
    x, foo.(x)
    # TODO test multiple columns
end

# apply_recipe args: Any[:(::Type{T}), :(x::T)]
@recipe function f(::Type{T}, x::T) where T <: AbstractArray{<:Union{Missing,<:Quantity}}
    # while plotting, change a vector of quantities to a unitless vector,
    # but pass the lost info on to the later in the pipeline. 
    _debug_recipes[1] && printstyled(color=:red, ":MechGluePlots ::Type{T}, x::T) where T <: AbstractArray{<:Union{Missing,<:Quantity}} \n")
    # DEBUG println(plotattributes)
    # Numeric type
    nut = numtype(eltype(x))
    # Prepare unitless output values
    vals = similar(x, nut)
    # Prior, if any, unit and series type info 
    vui = get(plotattributes, :unitinfo, SeriesUnitInfo[])
    for serno in 1:size(x, 2)
        sx = x[:, serno]
        u = unit(first((sx)))
        vui  = accumulate_unit_info(vui, plotattributes, u, serno)
        sux = nut.(ustrip(x[:, serno] ./ u))
        vals[:, serno] = sux
    end
    # DEBUG print_prettyln(vui) # table

    # Pass the info stripped from 'x' to dictionary 'plotattributes' in the pipeline 
    unitinfo := vui

    # Mark this series for dispatch to plot recipe, after we're done here.
    seriestype := :quantity_vector

    return vals
end


# This is called after unit info is stored
@recipe function f(::Type{Val{:quantity_vector}}, plt::AbstractPlot)
    _debug_recipes[1] && printstyled(color=:blue, ":MechGluePlots ::Type{Val{:quantity_vector}}, plt::AbstractPlot) \n")
    # Info stored earlier in the pipeline
    unitinfo = get(plotattributes, :unitinfo, nothing)
    index = get(plotattributes, :series_plotindex, 0)
    xlims =  get(plotattributes, :xlims, nothing)
    ylims =  get(plotattributes, :ylims, nothing)
    zlims =  get(plotattributes, :zlims, nothing)
    xlims_ul = isnothing(xlims) ? xlims : ustrip.(xlims)
    ylims_ul = isnothing(ylims) ? ylims : ustrip.(ylims)
    zlims_ul = isnothing(zlims) ? zlims : ustrip.(zlims)

    seriestyp = sertype(index, unitinfo)
    
    _debug_recipes[1] &&  print_prettyln(plotattributes)
    gx = get(plotattributes, :xguide, "")
    gy = get(plotattributes, :yguide, "")
    gz = get(plotattributes, :zguid, "")
    sux = axis_units_bracketed(:x, unitinfo)
    suy = axis_units_bracketed(:y, unitinfo)
    suz = axis_units_bracketed(:z, unitinfo)
    gux = gx == "" ? sux : gx * " " * sux
    guy = gy == "" ? suy : gy * " " * suy
    guz = gz == "" ? suz : gz * " " * suz
    plx = get(plotattributes, :x, nothing)
    ply = get(plotattributes, :y, nothing)
    plz = get(plotattributes, :z, nothing)
    # _debug_recipes[1] &&  println("guides: ", gux, guy, guz)
    # _debug_recipes[1] &&  println("series type: ", typeof(seriestyp), " ", seriestyp)

    # Delete our temporary series type used for dispatching
    pop!(plotattributes, :seriestype)
    @series begin # the macro copies plotattributes to this new series
        if !isnothing(seriestyp)
            seriestype := seriestyp # override plotattributes value
        end
        if !isnothing(plx) && gux != "[]"
            xguide := gux
        end
        if !isnothing(ply) && guy != "[]"
            yguide := guy
        end
        if !isnothing(plz) && guz != "[]"
            zguide := guz
        end
        # Axis limits might have quanity units, which we strip off.
        if !isnothing(xlims_ul)
            xlims := xlims_ul
        end
        if !isnothing(ylims_ul)
            ylims := ylims_ul
        end
        if !isnothing(zlims_ul)
            zlims := zlims_ul
        end
    end
end
@shorthands quantity_vector

end