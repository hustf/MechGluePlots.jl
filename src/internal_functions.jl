function relevant_key(attr)
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
    relevant_axis_guide = relevant_key(attr)
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

function axis_units_bracketed(axisletter, unitinfo::Vector{SeriesUnitInfo})
    setu = Set{String}()
    initialguide = ""
    for uinf in unitinfo[1:3]
        if uinf.letter == axisletter && !isnothing(uinf.unit_foo)
            initialguide *= string(uinf.unit_foo) * " "
        end
    end
    for uinf in unitinfo[4:end]
        uinf.letter == axisletter && push!(setu, string(uinf.unit_foo))
    end
    vu = sort(collect(setu))
    initialguide * "[" * join(setu, ", ") * "]"
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
    println("    Defaults")
    print_prettyln(attr.defaults)
end
"""
    cepad(s, n; p = ' ')
centerpad string s within length n
"""
cepad(s, n; p = ' ') = rpad(lpad(s,div(n + textwidth(string(s)), 2), p), n, p)



