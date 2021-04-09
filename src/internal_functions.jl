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
    if sertyp == :postfixit
        sertyp = nothing
    end
    addinfo = SeriesUnitInfo(serno, u, label, relevant_axis_guide, letter, sertyp)
    push!(vui, addinfo)
    vui
end

function axis_units_bracketed(axisletter, unitinfo::Vector{SeriesUnitInfo})
    setu = Set{String}()
    for uinf in unitinfo
        uinf.letter == axisletter && push!(setu, string(uinf.unit_foo))
    end
    vu = sort(collect(setu))
    "[" * join(setu, ", ") * "]"
end


function get_unevaluated_info(serno, unitinfo::Vector{SeriesUnitInfo})
    for uinf in reverse(unitinfo)
        ufo = uinf.unit_foo
        uinf.serno == serno && ufo isa Function && return uinf
    end
    nothing
end
is_evaluated(serno, unitinfo::Vector{SeriesUnitInfo}) = isnothing(get_unevaluated_info(serno, unitinfo))

function remove_fooinfo(unitinfo::Vector{SeriesUnitInfo}, serno)
    modinfo = SeriesUnitInfo[]
    for uinf in reverse(unitinfo)
        if uinf.serno == serno && uinf.unit_foo isa Function
            # pass over
        else
            push!(modinfo, uinf)
        end
    end
    modinfo
end

function evaluate_functions(serno, unitinfo, x, y, z)
    ui = get_unevaluated_info(serno, unitinfo)
    foo = ui.unit_foo
    toax = ui.letter
    # Error messages here will be hidden by 'ERROR: The backend must not support...'. Hence, we use @info.
    input, inputunit = if toax == :x
        y, get_unit(:y, ui.serno, unitinfo)
    elseif toax == :y
        x, get_unit(:x, ui.serno, unitinfo)
    elseif toax == :z
        emsg = "MechGluePlots does not yet support f(x,y) - surfaces. Evaluate in advance!"
        @error emsg
        throw(emsg)
    else
        emsg = "Could not determine input values to $foo. Continuing."
        @error emsg
    end
    if isa(input, AbstractArray{<:Union{Missing,<:Quantity}})
        emsg = "In evaluate_functions, expected a unitless vector. Continuing."
        @error emsg
    end
    input_quantitites = input ∙ inputunit
    values = map(foo, input_quantitites)
    toax, values
end


function get_unit(axisletter, serno, unitinfo::Vector{SeriesUnitInfo})
    for uinf in reverse(unitinfo)
        uinf.letter == axisletter && uinf.serno == serno && return uinf.unit_foo
    end
    emsg = "Could not determine unit of axis $axisletter and series no. $serno"
    @info emsg
    error(emsg)
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



function modified_ribbon(ribbon, serno, u)
    isnothing(ribbon) && return nothing
    _debug_recipes[1] && @show ribbon, serno, u
    thisrib = ribbon 
    thismod = if !isnothing(thisrib)
        if length(methods(thisrib)) == 0
            @info "It's a simple division"
            if thisrib isa Array
                thisrib[:, serno] / u
            else
                thisrib / u
            end
        else
            @info "It's not"
            @show methods(ribbon)
            x -> thisrib(x) / u
        end
    end
    if ribbon isa Array
        @show ribbon, thismod
        # This matrix will temporarily have different units in each column
        return hcat(ribbon[:, 1:serno-1], thismod, ribbon[:, serno+1:end])
    else
        return thismod
    end
end


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

function print_prettyln(plotattrib::Dict{Symbol, Any})
    for (ke, va) in plotattrib
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
function print_prettyln(plotattrib)
    println("{", typeof(plotattrib), "}")
    println(plotattrib)
end
function print_prettyln(plotattrib::Plots.RecipesPipeline.DefaultsDict)
    println("    Explicit")
    print_prettyln(plotattrib.explicit)
    println("    Defaults")
    print_prettyln(plotattrib.defaults)
end
"""
    cepad(s, n; p = ' ')
centerpad string s within length n
"""
cepad(s, n; p = ' ') = rpad(lpad(s,div(n + textwidth(string(s)), 2), p), n, p)



