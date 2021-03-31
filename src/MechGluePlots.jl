"Units in plots, for MechanicalUnits.jl>Unitful.jl"
module MechGluePlots
import Unitfu
import Unitfu: AbstractQuantity, Quantity, unit, ustrip, ∙
import Plots
import Plots: default
using RecipesBase

# In RecipesPipeline, this is called prior to recipes on single axis vectors.
# Replace the function with a vector of values, and let the rest be done further down the pipeline.
# @recipe function f(foo::F, x::T) where {F<:Function, T <: AbstractArray{<:Union{Missing,<:Quantity}}}
@recipe function f(foo::F, x::T) where {F<:Function, T <: AbstractArray}
    x, foo.(x) # Note the swap. For series with values, the ordinat is placed second.
end

@recipe function f(x::T, foo::F) where {F<:Function, T <: AbstractArray}
    # Without recipes, plot(0:10, sin) and plot(sin, 0:10) produce the same plot, sin on y. Same here:
    x, foo.(x)
end

function relevant_key(plotattr)
    if RecipesBase.is_explicit(plotattr, :letter)
        letter = plotattr[:letter]
        Symbol(letter, :guide)
    else
        :guide
    end
end

struct SeriesUnitInfo
    unit
    label
    relevant_axis_guide
    letter
    sertyp
end
import Base.show

function show(io::IO, v::T) where T<: Vector{SeriesUnitInfo}
    stabs(x) = lpad(x, 20)
    heading = ["[SeriesUnitInfo]", fieldnames(SeriesUnitInfo)...]
    printstyled(io, join(stabs.(heading)), "\n", color=:yellow)
    for si in v
        fields = fieldnames(SeriesUnitInfo)
        values = map(x-> getfield(si, x), fields)
        line = [" ", string.(values)...]
        println(io, join(stabs.(line)))
    end
end
    

function unit_info(plotattr, u)
    vui = get(plotattr, :unitinfo, SeriesUnitInfo[])
    letter = get(plotattr, :letter, nothing)
    relevant_axis_guide = relevant_key(plotattr)
    label = get(plotattr, :label, nothing)
    sertyp = get(plotattr, :seriestype, nothing)
    if sertyp == :quantity_vector
        sertyp = nothing
    end
    addinfo = SeriesUnitInfo(u, label, relevant_axis_guide, letter, sertyp)
    push!(vui, addinfo)
    vui
end


# apply_recipe args: Any[:(::Type{T}), :(x::T)]
@recipe function f(::Type{T}, x::T) where T <: AbstractArray{<:Union{Missing,<:Quantity}}
    # while plotting, modify a vector of quantities to unitless,
    # but push the unit info to the relevant place.
    printstyled(color=:blue, ":debug2 vq \n")
    ks = keys(plotattributes)
    for k in ks
        printstyled(k, "\t", color=:green)
        printstyled("=>", "\t", color=:black)
        printstyled(plotattributes[k], "\n", color=:yellow)
    end
    u = unit(eltype(x))
    all_unit_info  = unit_info(plotattributes, u)
    println("vq, all_unit_info = ")
    println(all_unit_info)
    unitinfo := all_unit_info
    seriestype --> :quantity_vector, :quiet
    #=
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
    =#
    qvals = ustrip(x ./ u)
    return qvals
end

function show_pretty(plotattributes)
    ks = keys(plotattributes)
    for k in ks
        if k == :unitinfo
            println("unitinfo=>")
            println(plotattributes[k])
        else
            printstyled(k, "\t", color=:green)
            printstyled("=>", "\t", color=:black)
            printstyled(plotattributes[k], "\n", color=:yellow)
        end
    end
end

function unit_conflicts(axisletter, unitinfo)
    # TODO - revert to returning formatter and ...
    false
end
function unit_axis(axisletter, unitinfo)
    i = 1
    while true
        inf = unitinfo[i]
        inf.letter == axisletter && return inf.unit
        i += 1
        i > length(unitinfo) && return nothing
    end
end

function sertype(axisletter, unitinfo::Vector{SeriesUnitInfo})
    i = 1
    while true
        inf = unitinfo[i]
        inf.letter == axisletter && return inf.sertyp
        i += 1
    end
end

function sertype(axisletter, plotattr)
    fromunitinfo = sertype(axisletter, get(plotattr, :unitinfo, nothing))
    if !isnothing(fromunitinfo)
        return fromunitinfo
    else
        return default(:seriestype)
    end
end

# This is called after unit info is stored
@recipe function f(::Type{Val{:quantity_vector}}, plt::AbstractPlot)
    # Collected when units were dropped
    unitinfo = get(plotattributes, :unitinfo, nothing)
    printstyled(color=:blue, "plot recipe\n")

    @assert length(unitinfo) < 3 "Too much unit info. Recipe not yet implemented."
    # User could also specify how to show units through a keyword
    kw_units_at_axes = Bool(get(plotattributes, :units_at_axes, true))
    conflicts_x = unit_conflicts(:x, unitinfo)
    conflicts_y = unit_conflicts(:y, unitinfo)
    conflicts_z = unit_conflicts(:z, unitinfo)
    show_pretty(plotattributes)
    plx = get(plotattributes, :x, nothing)
    ply = get(plotattributes, :y, nothing)
    plz = get(plotattributes, :z, nothing)
    @show plx
    @show ply
    @show plz
    seriestyp = sertype(:x, plotattributes)
    xguid = unit_axis(:x, unitinfo)
    yguid = unit_axis(:y, unitinfo)
    zguid = unit_axis(:z, unitinfo)

    @series begin # the macro copies plotattributes to this new series 
        seriestype := seriestyp # override plotattributes value
        if !conflicts_x && kw_units_at_axes && !isnothing(xguid)
            xguide --> xguid
        end
        if !conflicts_y && kw_units_at_axes && !isnothing(yguid)
            yguide --> yguid
        end
        if !conflicts_y && kw_units_at_axes && !isnothing(yguid)
            yguide --> yguid
        end
        if !isnothing(plx)
            x := ustrip(plx)
        end
        if !isnothing(ply)
            y := ustrip(ply)
        end
        if !isnothing(plz)
            z := ustrip(plz)
        end
    end
end
@shorthands quantity_vector











#= Series recipe
@recipe function f(::Type{Val{:quantity_vector}}, x, y, z)
    # Collected when units were dropped
    unitinfo = get(plotattributes, :unitinfo, nothing)
    printstyled(color=:blue, "series recipe unitinfo\n")
    println(unitinfo)    
    @assert length(unitinfo) < 3 "Too much unit info. Recipe not yet implemented."
    # User could also specify how to show units through a keyword
    kw_units_at_axes = Bool(get(plotattributes, :units_at_axes, true))
    conflicts_x = unit_conflicts(:x, unitinfo)
    conflicts_y = unit_conflicts(:y, unitinfo)
    conflicts_z = unit_conflicts(:z, unitinfo)


    ks = keys(plotattributes)
    for k in ks
       # printstyled(k, "\t", color=:green)
       # printstyled("=>", "\t", color=:black)
       # printstyled(plotattributes[k], "\n", color=:yellow)
    end
    plx = get(plotattributes, :x, x)
    ply = get(plotattributes, :y, y)
    plz = get(plotattributes, :z, z)

    @show plx, x
    @show ply
    @show plz
#    @show plotattributes[:serie]

    @series begin
        seriestype := :scatter
        label --> "lab"
        if !conflicts_x && kw_units_at_axes
            xguide --> unit_axis(:x, unitinfo)
        end
        x := ustrip(x)
        y := ustrip(y)
    end
end
=#



















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