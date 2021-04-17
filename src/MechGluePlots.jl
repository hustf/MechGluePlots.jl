"Units in plots, for MechanicalUnits.jl>Unitful.jl"
module MechGluePlots
import Unitfu
import Unitfu: AbstractQuantity, Quantity, unit, ustrip, ∙, numtype
import Plots
using Plots: default
#import Base: get, show
using RecipesBase
using RecipesBase: _debug_recipes
#import Plots.RecipesPipeline
#using RecipesPipeline: _scaled_adapted_grid, unzip
struct SeriesUnitInfo
    serno
    unit_foo
    label
    relevant_axis_guide
    letter
    sertyp
end

include("internal_functions.jl")

@recipe function f(foos::F, y::T) where {F<:Vector{Function}, T <: AbstractArray{<:Union{Missing,<:Quantity}}}
    _debug_recipes[1] && printstyled(color=:172, "\n    MechGluePlots foos::F, y::T) where {F<:Vector{Function}, T<: AbstractArray{<:Union{Missing,<:Quantity}}}\n")
    x = similar(y,  Quantity{T, D, U} where {T, D, U})
    vui = get(plotattributes, :unitinfo, SeriesUnitInfo[])
    for (f, serno) in zip(foos, (1:size(y, 2)))
        sy = y[:, serno]
        sx = map(f, sy)
        x[:, serno] = sx
        u = unit(first(sx))
        vui  = accumulate_unit_info(vui, plotattributes, u, serno; ax = :x)
        v = unit(first(sy))
        vui  = accumulate_unit_info(vui, plotattributes, v, serno; ax = :y)
    end
    _debug_recipes[1] && print_prettyln(vui)
    x, y
end
@recipe function f(foos::F, y::T) where {F<:Array{Function, 2}, T <: AbstractArray{<:Union{Missing,<:Quantity}}}
    _debug_recipes[1] && printstyled(color=:172, "\n    MechGluePlots foos::F, y::T) where {F<:Vector{Function}, T<: AbstractArray{<:Union{Missing,<:Quantity}}}\n")
    x = similar(y,  Quantity{T, D, U} where {T, D, U})
    vui = get(plotattributes, :unitinfo, SeriesUnitInfo[])
    for (f, serno) in zip(foos, (1:size(y, 2)))
        sy = y[:, serno]
        sx = map(f, sy)
        x[:, serno] = sx
        u = unit(first(sx))
        vui  = accumulate_unit_info(vui, plotattributes, u, serno; ax = :x)
        v = unit(first(sy))
        vui  = accumulate_unit_info(vui, plotattributes, v, serno; ax = :y)
    end
    _debug_recipes[1] && print_prettyln(vui)
    x, y
end

@recipe function f( x::T, foos::F) where {F<:Vector{Function}, T<: AbstractArray{<:Union{Missing,<:Quantity}}}
    _debug_recipes[1] && printstyled(color=:172, "\n    MechGluePlots x::T, foos::F) where {F<:Vector{Function}, T<: AbstractArray{<:Union{Missing,<:Quantity}}}\n")
    y = similar(x,  Quantity{T, D, U} where {T, D, U})
    vui = get(plotattributes, :unitinfo, SeriesUnitInfo[])
    for (f, serno) in zip(foos, (1:size(x, 2)))
        sx = x[:, serno]
        sy = map(f, sx)
        y[:, serno] = sy
        u = unit(first(sx))
        vui  = accumulate_unit_info(vui, plotattributes, u, serno; ax = :x)
        v = unit(first(sy))
        vui  = accumulate_unit_info(vui, plotattributes, v, serno; ax = :y)
    end
    _debug_recipes[1] && print_prettyln(vui)
    x, y
end

@recipe function f( x::T, foos::F) where {F<:Array{Function, 2}, T<: AbstractArray{<:Union{Missing,<:Quantity}}}
    _debug_recipes[1] && printstyled(color=:172, "\n    MechGluePlots x::T, foos::F) where {F<:Array{Function, 2}, T<: AbstractArray{<:Union{Missing,<:Quantity}}}\n")
    y = similar(x,  Quantity{T, D, U} where {T, D, U})
    vui = get(plotattributes, :unitinfo, SeriesUnitInfo[])
    error("this happens")

    for (f, serno) in zip(foos, (1:size(x, 2)))
        sx = x[:, serno]
        sy = map(f, sx)
        y[:, serno] = sy
        u = unit(first(sx))
        vui  = accumulate_unit_info(vui, plotattributes, u, serno; ax = :x)
        v = unit(first(sy))
        vui  = accumulate_unit_info(vui, plotattributes, v, serno; ax = :y)
    end
    _debug_recipes[1] && print_prettyln(vui)
    x, y
end
# In RecipesPipeline, this is called prior to recipes on single axis vectors.
# Replace the function with a vector of values, and let the rest be done further down the pipeline.
# @recipe function f(foo::F, x::T) where {F<:Function, T <: AbstractArray{<:Union{Missing,<:Quantity}}}

@recipe function f(foo::F, x::T)  where {F<:Function, T<:AbstractArray{<:Union{Missing,<:Quantity}}}
    _debug_recipes[1] && printstyled(color=:yellow, "\n    MechGluePlots foo::F, x::T)  where {F<:Function, T<:AbstractArray{<:Union{Missing,<:Quantity}}}\n")
    x, map(foo, x) # Note the swap. For series with values, the ordinat is placed second.
end

@recipe function f(x::T, foo::F) where {F<:Function, T<:AbstractArray{<:Union{Missing,<:Quantity}}}
    _debug_recipes[1] && printstyled(color=:yellow, "\n    MechGluePlots x::T, foo::F) where {F<:Function, T<:AbstractArray{<:Union{Missing,<:Quantity}}}\n")
    # Without recipes, plot(0:10, sin) and plot(sin, 0:10) produce the same plot, sin on y. Same here:
    x, map(foo, x)
end


#=
@recipe function f(f::Function, xmin::T, xmax::T) where T<: Quantity
    _debug_recipes[1] && printstyled(color=:yellow, "\n    MechGluePlots f::Function, xmin::T, xmax::T) where T<: Quantity\n")
    xscale, yscale = [get(plotattributes, sym, :identity) for sym in (:xscale, :yscale)]
    # Grab unit info here, otherwise do exactly the same as the fallback user recipe
    _scaled_adapted_grid(f, xscale, yscale, xmin, xmax)
end
=#

# We need to dispatch early in order to capture the unit information in a case like 
# plot( xlims =(-5s, 5s), [f_q_q, x-> 0.5f_q_q(1.5x)], ribbon = [x-> f_q_q(0.25x), x-> f_q_q(0.5x)])
@recipe function f(fs::AbstractArray{F}, xmin::T, xmax::T) where {F <: Function, T<:Quantity}
    _debug_recipes[1] && printstyled(color=:yellow, "\n    MechGluePlots fs::AbstractArray{F}, xmin::T, xmax::T) where {F <: Function, T<:Quantity}\n")
    ribbon = get(plotattributes, :ribbon, nothing)
    for (serno, f) in enumerate(fs)
        @series begin
            if !isnothing(ribbon)
                r = ribbon_series(ribbon, serno)
                ribbon := r
            end
            series_plotindex := serno
            f, xmin, xmax
        end
    end
    nothing
end


# apply_recipe args: Any[:(::Type{T}), :(x::T)]
#_apply_type_recipe(plotattributes::Any, v::AbstractArray, letter::Any) at type_recipe.jl:33
@recipe function f(::Type{T}, x::T) where T <: AbstractArray{<:Union{Missing,<:Quantity}}
    # while plotting, change a vector of quantities to a unitless vector,
    # but pass the lost info on to the later in the pipeline.
    _debug_recipes[1] && printstyled(color=:red, "\n    MechGluePlots ::Type{T}, x::T) where T <: AbstractArray{<:Union{Missing,<:Quantity}} \n")
    _debug_recipes[1] &&  println("    size(x) = $(size(x))")
    _debug_recipes[1] &&  print_prettyln(plotattributes)
    _debug_recipes[1] &&  println(" ")
    letter = plotattributes[:letter]
    # Prior, if any, unit and series type info
    vui = get(plotattributes, :unitinfo, SeriesUnitInfo[])
    ribbon = get(plotattributes, :ribbon, nothing)
    # Prepare unitless output values
    vals = similar(x, Float64)
    local modrib, u
    for colno in 1:size(x, 2)
        serno = get(plotattributes, :series_plotindex, colno)
        sx = x[:, colno]
        u = unit(first(sx))
        _debug_recipes[1] &&  println("        serno = $serno, u = $u")
        vui  = accumulate_unit_info(vui, plotattributes, u, serno)
        # Numeric type
        nut = numtype(first(sx))
        sux = map(nut, ustrip(x[:, colno] ./ u))
        vals[:, colno] = sux
        if !isnothing(ribbon)
            modrib = modified_ribbon(colno == 1 ? ribbon : modrib, serno, letter, u)
            if _debug_recipes[1]
                if ribbon isa Function || length(ribbon) == 1
                    println("    Original ribbon : $ribbon")
                    println("    Modified ribbon : $modrib")
                    if letter == :y && modrib isa Function
                        println("    Modified ribbon with unitless input: $modrib(0.5) = $(modrib(0.5))")
                    end
                else
                    println("    Original ribbon for series $serno: $(ribbon[serno])")
                    println("    Modified ribbon for series $serno: $(modrib[serno])")
                end
            end
        end
    end
    # Pass the info stripped from 'x' to dictionary 'plotattributes' in the pipeline
    unitinfo := vui
    if !isnothing(ribbon)
        ribbon := modrib
    end
    # Strip limits off units. Must be done early in the pipeline.
    li = get(plotattributes, Symbol(letter, :lims), nothing)
    if !isnothing(li)
        ulli = ustrip.(li)
        if letter == :x
            xlims := ustrip.(li)
        elseif letter == :y
            ylims := ustrip.(li)
        elseif letter == :z
            zlims := ustrip.(li)
        end
    end
    # For dispatch to series recipe
    seriestype := :postfixseries
    vals
end

#=

# We could evaluate ribbons more easily in this type recipe dispatch:
#Vector{Vector{Quantity{Float64,  ᵀ, FreeUnits{(s,),  ᵀ, nothing}}}}
@recipe function f(::Type{T}, x::T) where T <: AbstractArray{S} where S<:AbstractArray{<:Union{Missing,<:Quantity}}
    _debug_recipes[1] && printstyled(color=:blue, "\n    ::Type{T}, x::T) where T <: AbstractArray{S} where S<:AbstractArray{<:Union{Missing,<:Quantity}}\n")
    _debug_recipes[1] &&  println("    size(x) = $(size(x)), unit(first(first(x))) = $(unit(first(first(x))))")
    _debug_recipes[1] &&  print_prettyln(plotattributes)
    _debug_recipes[1] &&  println(" ")
    letter = plotattributes[:letter]
    ribbon = get(plotattributes, :ribbon, nothing)
    local ribvals = AbstractArray[]
    if !isnothing(ribbon)
        if size(x) == size(ribbon)
            for serno in 1:length(x)
                if ribbon[serno] isa Function
                    println("    We evaluate the ribbon functions for series $serno, and drop unit checks")
                    ribv = map(ribbon[serno], x[serno])
                    ulribv = ustrip.(ribv)
                    push!(ribvals, ulribv)
                end
            end
        end
    end
    ribbon:=ribvals
    x
   # x-> map(xi->map(usplit, xi), x), string
#=

    # Split into series, because nobody else will.
    @show length(x)
    delete!(plotattributes, :ribbon)
    for serno in 1:length(x)
        println("Now do series... $serno")
        @series begin
            subplot := serno
            if letter == :x
                if length(ribvals) >= serno
                    r = ribvals[serno]
                    ribbon := r
                end
                x := x[serno]
            elseif letter == :y
                if length(ribvals) >= serno
                    r = ribvals[serno]
                    ribbon := r
                end
                y := x[serno]
            elseif letter == :z
                if length(ribvals) >= serno
                    r = ribvals[serno]
                    ribbon := r
                end
                z := x[serno]
            end
        end
    end
    nothing
    =#
end

=#



#f(y), at user_recipe.jl:36
@recipe function f(foo::F, arg1::T, arg2::T) where {F <: Function, T <: AbstractArray{<:Union{Missing, <:Quantity}}}
    _debug_recipes[1] && printstyled(color=:172, "\n    foo::F, arg1::T, arg2::T) where {F <: Function, T <: AbstractArray{<:Union{Missing,<:Quantity}}}\n")
    map(foo, arg1), arg1, arg2
end


#f(x)
@recipe function f(arg1::T, foo::F, arg2::T) where {F <: Function, T <: AbstractArray{<:Union{Missing,<:Real}}}
    _debug_recipes[1] && printstyled(color=:172, "\n    arg1::T, foo::F, arg2::T) where {F <: Function, T <: AbstractArray{<:Union{Missing,<:Real}}}\n")
    # Prior, if any, unit and series type info
    vui = get(plotattributes, :unitinfo, SeriesUnitInfo[])
    isnothing(vui) && error("f(x): Wrong  MechGluePlots recipe triggered. Missing unit info.")
    # Evaluate foo with correct units, although they have been stripped from arg1 and arg2.
    u1, serno = axis_unit_series_no(:x, vui)
    # We'll pass on inlcuding units. If necessary, the pipeline will remove units and store the information.
    arg1, map(foo, arg1∙u1), arg2
end


@shorthands postfixseries
#=
@recipe function f(::Type{Val{:postfixseries}}, x, y, z)
    _debug_recipes[1] && printstyled(color=:blue, "\n    MechGluePlots ::Type{Val{:postfixseries}}, x, y, z)\n")

    # Info stored earlier in the pipeline
    _debug_recipes[1] &&  print_prettyln(plotattributes)

    unitinfo = plotattributes[:unitinfo]
    serno = plotattributes[:series_plotindex]

    gux = axis_units_bracketed(:x, unitinfo)
    guy = axis_units_bracketed(:y, unitinfo)
    guz = axis_units_bracketed(:z, unitinfo)

    # Units are normally stripped earlier in the pipeline, but this does not
    # occur with 'plot([f_q_q f_q_q], xlims = (2,3)s, ylims = (-10,-5)N)'
    if !isnothing(x) && !(eltype(x) <: Real)
        ul = map(numtype(eltype(x)), ustrip(x))
        x := ul
    end
    if !isnothing(y) && !(eltype(y) <: Real)
        ul = map(numtype(eltype(y)), ustrip(y))
        y := ul
    end
    if !isnothing(z) && !(eltype(z) <: Real)
        ul = map(numtype(eltype(z)), ustrip(z))
        z := ul
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

    seriestyp = sertype(serno, unitinfo)
    if isnothing(seriestyp)
        seriestype := default(:seriestype)
    else
        seriestype := seriestyp
    end
    return x, y, z
end
=#
@recipe function f(::Type{Val{:postfixseries}}, plt::AbstractPlot)
    _debug_recipes[1] && printstyled(color=:blue, "\n    MechGluePlots ::Type{Val{:postfixseries}}, plt)\n")
    # Info stored earlier in the pipeline for this series. There may be more. In that case, 
    # this will be called several times for the same plot.
    unitinfo = plotattributes[:unitinfo]
    serno = plotattributes[:series_plotindex]

    _debug_recipes[1] &&  print_prettyln(plotattributes)
 
    # Pick the interesting attributes dictionary from which to read existing guides
    read_from_plot_object = length(plt.attr.explicit) > 0
    read_attr = read_from_plot_object ? plt.attr.explicit : plotattributes
    if read_from_plot_object
        _debug_recipes[1] &&  println("    Previously stored attributes in plot object:")
        _debug_recipes[1] &&  print_prettyln(read_attr)
    end

    # Preserve existing guides and units, add bracketed units from this series
    gux = axis_guide_with_units(:x, read_attr, unitinfo)
    guy = axis_guide_with_units(:y, read_attr, unitinfo)
    guz = axis_guide_with_units(:z, read_attr, unitinfo)

    if serno == plt.n
        # Last series in plot, write to (local) plotattributes
        # and delete the temporary storage we used in 'plt'
        a = plt.attr.explicit
        if gux != ""
            xguide := gux
            haskey(a, :xguide) && pop!(a, :xguide)
        end
        if guy != ""
            yguide := guy
            haskey(a, :yguide) && pop!(a, :yguide)
        end
        if guz != ""
            zguide := guz
            haskey(a, :zguide) && pop!(a, :zguide)
        end
        _debug_recipes[1] && print_prettyln(plt.attr.explicit)
    else
        # Preserve 
        gux != "" && push!(plt.attr.explicit, (:xguide => gux))
        guy != "" && push!(plt.attr.explicit, (:yguide => guy))
        guz != "" && push!(plt.attr.explicit, (:zguide => guz))
    end
    # Signal to the pipeline that we're through with this series
    seriestyp = sertype(serno, unitinfo)
    seriestype := seriestyp
    plt
end

end