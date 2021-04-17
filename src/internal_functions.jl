function relevant_guide_key(attr)
    if RecipesBase.is_explicit(attr, :letter)
        letter = attr[:letter]
        Symbol(letter, :guide)
    else
        :guide
    end
end

function accumulate_unit_info(vui, attr, u, serno; ax = nothing)
    if length(vui) == 0
        # Store pre-existing guide strings in "series 0"
        gx = get(attr, :xguide, nothing)
        gy = get(attr, :yguide, nothing)
        gz = get(attr, :zguid, nothing)
        addinfo = SeriesUnitInfo(0, gx, nothing, nothing, :x, nothing)
        push!(vui, addinfo)
        addinfo = SeriesUnitInfo(0, gy, nothing, nothing, :y, nothing)
        push!(vui, addinfo)
        addinfo = SeriesUnitInfo(0, gz, nothing, nothing, :z, nothing)
        push!(vui, addinfo)
    end

    letter = get(attr, :letter, nothing)
    if isnothing(letter)
        letter = ax
    end
    relevant_axis_guide = relevant_guide_key(attr)
    label = get(attr, :label, nothing)
    sertyp = get(attr, :seriestype, nothing)
    if sertyp == :postfixseries
        sertyp = nothing
    end
    if typeof(label) <: AbstractArray
        label = label[serno]
    end
    if typeof(sertyp) <: AbstractArray && sertyp[serno] != :postfixseries
        sertyp = sertyp[serno]
    end
    addinfo = SeriesUnitInfo(serno, u, label, relevant_axis_guide, letter, sertyp)
    push!(vui, addinfo)
    vui
end

units_from_string(st) = Set{String}([ma.captures[1] for ma in eachmatch(r"\[(.*?)\]", st)])

function axis_guide_with_units(letter, attrdic, unitinfo::Vector{SeriesUnitInfo})
    existing_guide_string = string(get(attrdic, Symbol(letter, :guide), ""))
    # Collect units for the axis, one instance only
    existing_units = units_from_string(existing_guide_string )
    new_u = Set{String}()
    for uinf in unitinfo[4:end]
        uinf.letter == letter && push!(new_u, string(uinf.unit_foo))
    end
    add_units = setdiff(new_u,  existing_units)
    add_string = if length(add_units) == 0
        ""
    else
        "[" * join(collect(add_units), "], [") * "]"
    end
    if length(add_string) == 0
        existing_guide_string
    else
        if length(existing_units) > 0
            existing_guide_string * ", " * add_string
        else
            existing_guide_string * " " * add_string
        end
    end
end


function axis_unit_series_no(axisletter, unitinfo::Vector{SeriesUnitInfo})
    for uinf in reverse(unitinfo)
        uinf.letter == axisletter && return uinf.unit_foo, uinf.serno
    end
    error("Could not determine axis unit and series number")
end

function sertype(index, unitinfo::Vector{SeriesUnitInfo})
    for uinf in reverse(unitinfo)
        uinf.serno == index && !isnothing(uinf.sertyp) && return uinf.sertyp
    end
    default(:seriestype)
end

_modified_ribbon(ribbon, u) = ribbon / u
_modified_ribbon(ribbon::Function, u) = x-> ribbon(x) / (1u)

function modified_ribbon(ribbon::T, serno, letter, u) where T<:Union{Missing,<:Quantity}
    if letter == :y
        ribbon / u
    else
        ribbon
    end
end

function modified_ribbon(ribbon::T, serno, letter, u) where T<:Tuple
    if letter ==:y
        map(ribbon) do r
            modified_ribbon(r, serno, letter, u)
        end
    else
        ribbon
    end
end

function modified_ribbon(ribbon::T, serno, letter, u) where T<:AbstractRange
    if letter ==:y
        broadcast(se-> _modified_ribbon(se, u), ribbon)
    else
        ribbon
    end
end

function modified_ribbon(ribbon::T, serno, letter, u) where T<:Matrix
    _debug_recipes[1] && printstyled(color=:yellow, "\n    MechGluePlots modified_ribbon($ribbon<:Matrix, $serno, $letter, $u)\n")
    if letter ==:y
        if size(ribbon, 2) > 1
            # Branch to modify
            serib = ribbon[:, serno]
            # Modified branch
            modrib_se = broadcast(se-> _modified_ribbon(se, u), serib)
            # We are only modifying the branch of this tree relevant to the series, but we need to
            # return all of the tree. Most likely, an Array{Any}
            hcat(ribbon[:, 1:serno-1], modrib_se, ribbon[:, serno + 1:end])
        else
            ribbon / u
        end
    else
        ribbon
    end
end


function modified_ribbon(ribbon::T, serno, letter, u) where T<:Matrix{Function}
    _debug_recipes[1] && printstyled(color=:green, "\n    MechGluePlots modified_ribbon($ribbon<:Matrix{Function}, $serno, $letter, $u)\n")
    if size(ribbon, 2) > 1
        # Branch to modify
        serib = ribbon[:, serno]
        # Modified branch
        modrib_se = broadcast(se-> modified_ribbon(se, serno, letter, u), serib)
        # We are only modifying the branch of this tree relevant to the series, but we need to
        # return all of the tree. 
        hcat(ribbon[:, 1:serno-1], modrib_se, ribbon[:, serno + 1:end])
    else
        error("This form of the ribbon argument is not implemented with quantity plots")
    end
end

function modified_ribbon(ribbon::T, serno, letter, u) where T<:Vector{Function}
    _debug_recipes[1] && printstyled(color=:green, "\n    MechGluePlots modified_ribbon($ribbon<:Vector{Function}, $serno, $letter, $u)\n")
    if size(ribbon, 1) > 1
        # Branch to modify
        se = ribbon[serno]
        # Modified branch
        modrib_se = modified_ribbon(se, serno, letter, u)
        # We are only modifying the branch of this tree relevant to the series, but we need to
        # return all of the tree. 
        vcat(ribbon[1:serno-1], modrib_se, ribbon[serno + 1:end])
    else
        error("This form of the ribbon argument is not implemented with quantity plots")
    end
end

function modified_ribbon(ribbon::Function , serno, letter, u)
    _debug_recipes[1] && printstyled(color=:yellow, "\n    MechGluePlots modified_ribbon($ribbon::Function, $serno, $letter, $u)\n")
    if letter == :y
        # u is the defined output unit
        #x-> ribbon(IntArg(x)) / (1u)
        x-> ribbon(x) / (1u)
    else
        # u is the defined input unit
        #x::IntArg -> ribbon(x.val∙u)
        x -> ribbon(x∙u)
    end
end


function modified_ribbon(ribbon::T , serno, letter, u) where T
    @info T
    @info ribbon
    error("This form of the ribbon argument is not implemented with quantity plots")
end

"""
    ribbon_series(ribbon, serno)
Extract the part of 'ribbon' structure that belongs to 'series' no,
without evaluating - ribbon may be a function.

This mimicks the way the 'ribbon' argument is interpreted by 'Plots.jl',
although that would evaluate directly.
"""
function ribbon_series(ribbon::Tuple{S, T}, serno) where {S, T}
    (ribbon_series(ribbon[1], serno), 
    ribbon_series(ribbon[2], serno))
end
ribbon_series(ribbon, serno) = ribbon[serno]
ribbon_series(ribbon::Matrix, serno) = ribbon_series[:, serno]
ribbon_series(ribbon::Nothing, serno) = ribbon
ribbon_series(ribbon::Number, serno) = ribbon
ribbon_series(ribbon::Function, serno) = ribbon
ribbon_series(ribbon::AbstractRange, serno) = ribbon

##########################
#  Print debug functions
#  To use, call:
#  RecipesBase.debug(true)
##########################

function print_prettyln(v::T) where T <: Vector{SeriesUnitInfo}
    headings =  string.(fieldnames(SeriesUnitInfo))
    lens = map(s -> length(s), headings )
    heading = "               " * join(map(headings, lens) do h, l
        cepad(h, l + 2)
    end)
    printstyled(stderr, heading, "\n", color=:yellow)
    for si in v
        fields = fieldnames(SeriesUnitInfo)
        vs = [map(x-> string(getfield(si, x)), fields)..., "]"]
        vspad = map((h, l) -> cepad(h,l), vs, lens)
        line = " SeriesUnitInfo(" * join(vspad, ',') * ")"
        println(stderr, line)
    end
end

function print_prettyln(attr::Dict{Symbol, Any})
    for (ke, va) in attr
        if ke == :unitinfo
            printstyled(lpad("unitinfo", 18), "    =>\n", color = :green)
            print_prettyln(va)
        else
            printstyled(lpad(ke, 18), color=:green)
            print(IOContext(stderr, :limit=>true), "    => ", va, "\n")
        end
    end
    println(" ")
end
function print_prettyln(attr)
    println("{", typeof(attr), "}")
    println(attr)
end
function print_prettyln(attr::Plots.RecipesPipeline.DefaultsDict)
    println("    Explicit")
    print_prettyln(attr.explicit)
    if length(keys(attr.defaults)) < 10
        println("    Defaults")
        print_prettyln(attr.defaults)
    else
        println("    Defaults (not shown, length $(length(keys(attr.defaults))))")
    end
end
"""
    cepad(s, n; p = ' ')
centerpad string s within length n
"""
cepad(s, n; p = ' ') = rpad(lpad(s,div(n + textwidth(string(s)), 2), p), n, p)
