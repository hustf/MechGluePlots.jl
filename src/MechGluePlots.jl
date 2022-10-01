"Units in plots, for MechanicalUnits.jl>Unitful.jl"
module MechGluePlots
import Unitfu
using Unitfu: Quantity, unit, ustrip, ∙, numtype
import Plots
using Plots: default
using RecipesBase
using RecipesBase: _debug_recipes
struct SeriesUnitInfo
    serno
    unit_foo
    label
    relevant_axis_guide
    letter
    sertyp
end

include("internal_functions.jl")

#########
# Arguments that are spit into series to handle units by series
# In a few combinations of arguments, we need to split before evaluating
# in order to capture the unit information. E.g. in a case like
# plot( xlims =(-5s, 5s), [f_q_q, x-> 0.5f_q_q(1.5x)], ribbon = [x-> f_q_q(0.25x), x-> f_q_q(0.5x)])
#########

@recipe function f(fs::AbstractArray{F}, xmin::T, xmax::T) where {F <: Function, T<:Quantity}
    _debug_recipes[1] && printstyled(color=:172, "\n    MechGluePlots fs::AbstractArray{F}, xmin::T, xmax::T) where {F <: Function, T<:Quantity}\n")
    ribbon = get(plotattributes, :ribbon, nothing)
    for (serno, f) in enumerate(fs)
        @series begin
            if !isnothing(ribbon)
                r = extract_series(ribbon, serno)
                ribbon := r
            end
            series_plotindex := serno
            f, xmin, xmax
        end
    end
    nothing
end

@recipe function f(fs::VecOrMat{F}, y::T) where {F<:Function, T <: AbstractArray{<:Union{Missing,<:Quantity}}}
    _debug_recipes[1] && printstyled(color=:172, "\n    MechGluePlots fs::AbstractArray{F}, y::T) where {F<:Function, T <: AbstractArray{<:Union{Missing,<:Quantity}}}\n")
    ribbon = get(plotattributes, :ribbon, nothing)
    for (serno, f) in enumerate(fs)
        @series begin
            if !isnothing(ribbon)
                r = extract_series(ribbon, serno)
                ribbon := r
            end
            ys = extract_series(y, serno)
            series_plotindex := serno
            f, ys
        end
    end
end

@recipe function f( x::T, fs::VecOrMat{F}) where {F<:Function, T <: AbstractArray{<:Union{Missing,<:Quantity}}}
    _debug_recipes[1] && printstyled(color=:172, "\n    MechGluePlots  where {F<:Function, T <: AbstractArray{<:Union{Missing,<:Quantity}}}\n")
    ribbon = get(plotattributes, :ribbon, nothing)
    for (serno, f) in enumerate(fs)
        @series begin
            if !isnothing(ribbon)
                r = extract_series(ribbon, serno)
                ribbon := r
            end
            xs = extract_series(x, serno)
            series_plotindex := serno
            xs, f
        end
    end
end

#########
# Arguments that are evalated before quantities are dropped
# from axes. For example,
# plot(xlims = (0, 10)s, sin(t /s))
# needs to be evaluated before 'xlims' is converted to a unitless tuple.
#########

@recipe function f(foo::F, x::T)  where {F<:Function, T<:AbstractArray{<:Union{Missing,<:Quantity}}}
    _debug_recipes[1] && printstyled(color=:yellow, "\n    MechGluePlots foo::F, x::T)  where {F<:Function, T<:AbstractArray{<:Union{Missing,<:Quantity}}}\n")
    x, map(foo, x) # Note the swap. For series with values, the ordinat is placed second.
end

@recipe function f(x::T, foo::F) where {F<:Function, T<:AbstractArray{<:Union{Missing,<:Quantity}}}
    _debug_recipes[1] && printstyled(color=:yellow, "\n    MechGluePlots x::T, foo::F) where {F<:Function, T<:AbstractArray{<:Union{Missing,<:Quantity}}}\n")
    # Without recipes, plot(0:10, sin) and plot(sin, 0:10) produce the same plot, sin on y. Same here:
    x, map(foo, x)
end

#########
# Arguments that include quantities.
# In the pipeline, functions are evaluated using units.
# If the evaluated functions include units, the result wil be stripped of
# units here. The information is not lost, but stored in 'plotattributes[:unitinfo].
# Data that pass through here are temporarily assigned type :postfixseries.
# For such series, the stored unit info is added to axis guides after all series
# have been parsed.
#########

@recipe function f(::Type{T}, x::T) where T <: AbstractArray{<:Union{Missing,<:Quantity}}
    # while plotting, change a vector of quantities to a unitless vector,
    # but pass the lost info on to the later in the pipeline.
    _debug_recipes[1] && printstyled(color=:red, "\n    MechGluePlots ::Type{T}, x::T) where T <: AbstractArray{<:Union{Missing,<:Quantity}} \n")
    _debug_recipes[1] &&  println("    size(x) = $(size(x))")
    _debug_recipes[1] &&  print_prettyln(plotattributes)
    _debug_recipes[1] &&  println(" ")
    serno = get(plotattributes, :series_plotindex, 1)
    letter = plotattributes[:letter]
    # Prior, if any, unit and series type info
    vui = get(plotattributes, :unitinfo, SeriesUnitInfo[])
    # How can we tell if there are more series or not?
    # this is how: Multiple column x, but one row vector: The folloing columns are ignored.
    # But with one column vector, everything is supposed to belong to this series.
    # So passing one column in, everything belong to the first series.

    ribbon = get(plotattributes, :ribbon, nothing)
    # Prepare unitless output values
    vals = similar(x, Float64)
    local modrib, u
    # When in a type recipe, we can't actually split in two series,
    # but we can take note of units, strip them, and passively let the split be done by other
    # parts of the pipeline.
    # For the 'ribbon', this is a bit more complicated but essentially we do the same.
    for colno in 1:size(x, 2)
        thisserno = serno + colno - 1

        sx = x[:, colno]
        u = unit(first(sx))
        _debug_recipes[1] &&  println("        serno = $serno, u = $u")
        vui  = accumulate_unit_info(vui, plotattributes, u, thisserno)
        # Numeric type
        nut = numtype(first(sx))
        sux = map(nut, ustrip.(x[:, colno] ./ u))
        vals[:, colno] = sux
        if !isnothing(ribbon)
            modrib = modified_ribbon(colno == 1 ? ribbon : modrib, colno, letter, u)
            if _debug_recipes[1]
                    println("    Original ribbon : $ribbon")
                    println("    Modified ribbon : $modrib")
                    if letter == :y && modrib isa Function
                        println("    Modified ribbon with unitless input: $modrib(0.5) = $(modrib(0.5))")
                    end
            end
        end
    end
    # Pass the info stripped from 'x' to dictionary 'plotattributes' in the pipeline
    unitinfo := vui
    if !isnothing(ribbon)
        ribbon := modrib
    end
    # Strip units off limits.
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


#########
# Functions with arguments that include quantities.
# We do the evaluation here, since the order in which
# limits are determined by Plots.jl varies depending on
# the order of arguments.
#########


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


#########
# Lastly, find the info about stripped units again.
# This is triggered once per series, but we can now access
# a storage that is common to all series (we couldn't before!).
# When the current series is the last series, the accumulated
# info is placed on the axis guides.
#########

@shorthands postfixseries
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