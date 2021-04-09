"Units in plots, for MechanicalUnits.jl>Unitful.jl"
module MechGluePlots
import Unitfu
import Unitfu: AbstractQuantity, Quantity, unit, ustrip, ∙, numtype
import Plots
import Plots: default
import Base: show, get
import RecipesBase._debug_recipes
using RecipesBase
struct SeriesUnitInfo
    serno
    unit_foo
    label
    relevant_axis_guide
    letter
    sertyp
end

include("internal_functions.jl")



@recipe function f(foos::F, y::T) where {F<:Vector{Function}, T <: AbstractArray}
    _debug_recipes[1] && printstyled(color=:172, "\n    MechGluePlots foos::F, y::T) where {F<:Vector{Function}, T<: AbstractArray{<:Union{Missing,<:Quantity}}}\n")
    x = similar(y,  Quantity{T, D, U} where {T, D, U})
    for (f, serno) in zip(foos, (1:size(y, 2)))
        sy = y[:, serno]
        sx = map(f, sy)
        x[:, serno] = sx
    end
    x, y
end

@recipe function f( x::T, foos::F) where {F<:Vector{Function}, T<: AbstractArray{<:Union{Missing,<:Quantity}}}
    _debug_recipes[1] && printstyled(color=:172, "\n    MechGluePlots x::T, foos::F) where {F<:Vector{Function}, T<: AbstractArray{<:Union{Missing,<:Quantity}}}\n")
    y = similar(x,  Quantity{T, D, U} where {T, D, U})
    for (f, serno) in zip(foos, (1:size(x, 2)))
        sx = x[:, serno]
        sy = map(f, sx)
        y[:, serno] = sy
    end
    x, y
end


# In RecipesPipeline, this is called prior to recipes on single axis vectors.
# Replace the function with a vector of values, and let the rest be done further down the pipeline.
# @recipe function f(foo::F, x::T) where {F<:Function, T <: AbstractArray{<:Union{Missing,<:Quantity}}}
@recipe function f(foo::F, x::T)  where {F<:Function, T<:AbstractArray}
    _debug_recipes[1] && printstyled(color=:yellow, "\n    MechGluePlots foo::F, x::T)  where {F<:Function, T<:AbstractArray}\n")
    x, map(foo, x) # Note the swap. For series with values, the ordinat is placed second.
end 


@recipe function f(x::T, foo::F) where {F<:Function, T<:AbstractArray}
    _debug_recipes[1] && printstyled(color=:yellow, "\n    MechGluePlots x::T, foo::F) where {F<:Function, T<:AbstractArray}\n")
    # Without recipes, plot(0:10, sin) and plot(sin, 0:10) produce the same plot, sin on y. Same here:
    x, map(foo, x)
end




# apply_recipe args: Any[:(::Type{T}), :(x::T)]
#_apply_type_recipe(plotattributes::Any, v::AbstractArray, letter::Any) at type_recipe.jl:33
@recipe function f(::Type{T}, x::T) where T <: AbstractArray{<:Union{Missing,<:Quantity}}
    # while plotting, change a vector of quantities to a unitless vector,
    # but pass the lost info on to the later in the pipeline. 
    _debug_recipes[1] && printstyled(color=:red, "\n    MechGluePlots ::Type{T}, x::T) where T <: AbstractArray{<:Union{Missing,<:Quantity}} \n")
    _debug_recipes[1] &&  print_prettyln(plotattributes)
    _debug_recipes[1] &&  println(" ")
    # Prepare unitless output values
    vals = similar(x, Float64)
    # Prior, if any, unit and series type info 
    vui = get(plotattributes, :unitinfo, SeriesUnitInfo[])
    ribbon = get(plotattributes, :ribbon, nothing)
    for serno in 1:size(x, 2)
        sx = x[:, serno]
        u = unit(first(sx))
        vui  = accumulate_unit_info(vui, plotattributes, u, serno)
        # Numeric type
        nut = numtype(first(sx))
        sux = nut.(ustrip(x[:, serno] ./ u))
        vals[:, serno] = sux
        ribbon = modified_ribbon(ribbon, serno, u)
    end
    # Pass the info stripped from 'x' to dictionary 'plotattributes' in the pipeline 
    unitinfo := vui
    if !isnothing(ribbon)
        @show ribbon
        ribbon := ribbon
    end
    seriestype := :postfixit
    return vals
end

#=
# target plot(myq, [f_q_q, x-> 0.8f_q_q(1.25x)])
#_apply_type_recipe(plotattributes::Any, v::AbstractArray, letter::Any) at type_recipe.jl:33]
@recipe function f(::Type{T}, v::T) where {T<:Vector{Function}}
    _debug_recipes[1] && printstyled(color=:172, "\n    :Type{T}, x::T) where {T<:Vector{Function}}\n")
     # _debug_recipes[1] &&  print_prettyln(plotattributes)
    # Prior, if any, unit and series type info 
    vui = get(plotattributes, :unitinfo, SeriesUnitInfo[])
    if length(vui) > 1
        # Store functions in plotattributes, as units (units are callables too)
        for serno in 1:size(v,1)
            foo = v[serno]
            vui  = accumulate_unit_info(vui, plotattributes, foo, serno)
        end
        # Pass the info stripped from 'x' to dictionary 'plotattributes' in the pipeline 
        unitinfo := vui
        # Return v to the pipeline won't dispatch on the series type quanity_vector later in the pipeline.
        # But we can trigger a new round through the pipeline:
        @series begin end
    else
        # Don't interfere if the arguments are not quantities
        v
    end
end
=#

#f(y), at user_recipe.jl:36
@recipe function f(foo::F, arg1::T, arg2::T) where {F <: Function, T <: AbstractArray{<:Union{Missing,<:Quantity}}}
    _debug_recipes[1] && printstyled(color=:172, "\n    foo::F, arg1::T, arg2::T) where {F <: Function, T <: AbstractArray{<:Union{Missing,<:Quantity}}}\n")
    map(foo, arg1), arg1, arg2
end



#f(x)
@recipe function f(arg1::T, foo::F, arg2::T) where {F <: Function, T <: AbstractArray{<:Union{Missing,<:Real}}}
    _debug_recipes[1] && printstyled(color=:172, "\n    arg1::T, foo::F, arg2::T) where {F <: Function, T <: AbstractArray{<:Union{Missing,<:Real}}}\n")
    @show stacktrace()[2:4]
    #_debug_recipes[1] &&  print_prettyln(plotattributes)
    # Prior, if any, unit and series type info
    vui = get(plotattributes, :unitinfo, SeriesUnitInfo[])
    isnothing(vui) && error("f(x): Wrong  MechGluePlots recipe triggered. Missing unit info.")
    # Evaluate foo with correct units, although they have been stripped from arg1 and arg2.
    u1, serno = axis_unit_series_no(:x, vui)
    # We'll pass on inlcuding units. If necessary, the pipeline will remove units and store the information.
    arg1, map(foo, arg1∙u1), arg2  
end


#=

# Not needed below...

@recipe function f(::Type{Val{:function_vector}}, plt)
    _debug_recipes[1] && printstyled(color=:blue, "\n    MechGluePlots \n")
    _debug_recipes[1] &&  print_prettyln(plotattributes)
    @show stacktrace()[2:4]
    @show typeof(plt)
    @show plt
    error("ou")
    return plt
end

@recipe function f(::Type{Val{:function_vector}}, plt, arg1)
    _debug_recipes[1] && printstyled(color=:blue, "\n    MechGluePlots \n")
    _debug_recipes[1] &&  print_prettyln(plotattributes)
    @show stacktrace()[2:4]
    @show typeof(plt)
    @show plt
    error("ouc")
    return plt, arg1
end

@recipe function f(::Type{Val{:function_vector}}, plt, arg1, arg2)
    _debug_recipes[1] && printstyled(color=:blue, "\n    MechGluePlots \n")
    _debug_recipes[1] &&  print_prettyln(plotattributes)
    @show stacktrace()[2:4]
    @show typeof(plt)
    @show plt
    error("ouch")
    return plt, arg1, arg2
end

@recipe function f(fvp::Val{:function_vector})
    _debug_recipes[1] && printstyled(color=:blue, "\n    MechGluePlots \n")
    _debug_recipes[1] &&  print_prettyln(plotattributes)
    @show stacktrace()[2:4]
    @show fvp
    error("user plot here")
    return fvp
end

# First self-defined series type.
@recipe function f(::Type{Val{:quantity_vector}}, x, y, z)
    _debug_recipes[1] && printstyled(color=:blue, "\n    MechGluePlots ::Type{Val{:quantity_vector}}, x, y, z)\n")
    # Info stored earlier in the pipeline
    _debug_recipes[1] &&  print_prettyln(plotattributes)

    unitinfo = plotattributes[:unitinfo]
    @assert !isnothing(unitinfo)
    serno = plotattributes[:series_plotindex]
    if !is_evaluated(serno, unitinfo)
        # Evaluate and find unitless version
        letter, qvalues = evaluate_functions(serno, unitinfo, x, y, z)
        nut = numtype(eltype(qvalues))
        u = unit(first(qvalues))
        ul_values = nut.(ustrip(qvalues ./ u))
        # update plotattributes
        if letter == :x
            x := ul_values
        elseif letter == :y
            y := ul_values
        elseif letter == :z
            z:= ul_values
        else
            @error "Could not assing evaluated function values to plot attribute $letter. Continuing."
        end
        unitinfo = remove_fooinfo(unitinfo, serno)
        unitinfo = accumulate_unit_info(unitinfo, plotattributes, u, serno)
        unitinfo := unitinfo
    end
    # With this series evaluated, we'll pass it on:
    seriestype := :postfixit
end

=#
#=
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
=#
# Second self-defined series type
@shorthands postfixit
@recipe function f(::Type{Val{:postfixit}}, x, y, z)
    _debug_recipes[1] && printstyled(color=:blue, "\n    MechGluePlots ::Type{Val{:postfixit}}, x, y, z)\n")

    # Info stored earlier in the pipeline
    _debug_recipes[1] &&  print_prettyln(plotattributes)


    #temporary
    _debug_recipes[1] &&  print_prettyln(plotattributes[:extra_kwargs])
    unitinfo = plotattributes[:unitinfo]
    serno = plotattributes[:series_plotindex]

    gx = get(plotattributes, :xguide, "")
    gy = get(plotattributes, :yguide, "")
    gz = get(plotattributes, :zguid, "")

    sux = axis_units_bracketed(:x, unitinfo)
    suy = axis_units_bracketed(:y, unitinfo)
    suz = axis_units_bracketed(:z, unitinfo)
    gux = gx == "" ? sux : gx * " " * sux
    guy = gy == "" ? suy : gy * " " * suy
    guz = gz == "" ? suz : gz * " " * suz

    xlims =  get(plotattributes, :xlims, nothing)
    ylims =  get(plotattributes, :ylims, nothing)
    zlims =  get(plotattributes, :zlims, nothing)
    xlims_ul = isnothing(xlims) ? xlims : ustrip.(xlims)
    ylims_ul = isnothing(ylims) ? ylims : ustrip.(ylims)
    zlims_ul = isnothing(zlims) ? zlims : ustrip.(zlims)

    # Remove the temporary dispatch series type.
    
    seriestyp = sertype(serno, unitinfo)
    if isnothing(seriestyp)
        seriestype := default(:seriestype)
    else
        seriestype := seriestyp
    end
    

    # Units are normally stripped earlier in the pipeline, but this does not seem
    # to occur with 'plot([f_q_q f_q_q], xlims = (2,3)s, ylims = (-10,-5)N)'
    if !isnothing(x) && !(eltype(x) <: Real)
        plx_ul = ustrip(x)
        x := plx_ul
    end
    if !isnothing(y) && !(eltype(y) <: Real)
        ply_ul = ustrip(y)
        y := ply_ul
    end
    if !isnothing(z) && !(eltype(z) <: Real)
        plz_ul = ustrip(z)
        z := plz_ul
    end


    if !isnothing(x) && gux != "[]"
        xguide := gux
    end
    if !isnothing(y) && guy != "[]"
        yguide := guy
    end
    if !isnothing(z) && guz != "[]"
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
    return x, y, z
end














end