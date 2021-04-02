function relevant_key(plotattr)
    if RecipesBase.is_explicit(plotattr, :letter)
        letter = plotattr[:letter]
        Symbol(letter, :guide)
    else
        :guide
    end
end


function accumulate_unit_info(vui, plotattr, u, serno)
    letter = get(plotattr, :letter, nothing)
    relevant_axis_guide = relevant_key(plotattr)
    label = get(plotattr, :label, nothing)
    sertyp = get(plotattr, :seriestype, nothing)
    if typeof(label) <: AbstractArray
        label = label[serno]
    end
    if typeof(sertyp) <: AbstractArray
        sertyp = sertyp[serno]
    end
    if sertyp == :quantity_vector
        sertyp = nothing
    end
    addinfo = SeriesUnitInfo(serno, u, label, relevant_axis_guide, letter, sertyp)
    # DEBUG println(addinfo)
    push!(vui, addinfo)
    vui
end

function axis_units_bracketed(axisletter, unitinfo::Vector{SeriesUnitInfo})
    setu = Set{String}()
    for uinf in unitinfo
        uinf.letter == axisletter && push!(setu, string(uinf.unit))
    end
    vu = sort(collect(setu))
    "[" * join(setu, ", ") * "]"
end

function sertype(index, unitinfo::Vector{SeriesUnitInfo})
    for uinf in unitinfo
        uinf.serno == index && !isnothing(uinf.sertyp) && return uinf.sertyp
    end
    default(:seriestype)
end

function print_prettyln(v::T) where T <: Vector{SeriesUnitInfo}
    headings =  string.(fieldnames(SeriesUnitInfo))
    lens = map(s -> length(s), headings )
    heading = "               " * join(map(headings, lens) do h, l
        cpad(h, l + 2)
    end)
    printstyled(stderr, "\n", heading, "\n", color=:yellow)
    for si in v
        fields = fieldnames(SeriesUnitInfo)
        vs = [map(x-> string(getfield(si, x)), fields)..., "]"]
        vspad = map((h, l) -> cpad(h,l), vs, lens)
        line = " SeriesUnitInfo(" * join(vspad, ',') * ")"
        println(stderr, line)
    end
end

function print_prettyln(plotattrib::Dict{Symbol, Any})
    for (ke, va) in plotattrib
        if ke == :unitinfo
            printstyled("unitinfo  =>\n", color = :green)
            print_prettyln(va)
        else
            printstyled(rpad(ke, 18), color=:green)
            print(" => ", va, "\n")
        end
    end
end


"""
    cpad(s, n; p = ' ')
centerpad string s within length n
"""
cpad(s, n; p = ' ') = rpad(lpad(s,div(n + textwidth(string(s)), 2), p), n, p)