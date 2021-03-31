#=
default(titlefont = (20, "times"), legendfontsize = 26, 
    guidefont = (30, :darkgreen), tickfont = (24, :orange), 
    framestyle = :origin, minorgrid = true,
    legend = :topleft, linewidth = 4,
    bottom_margin = 18px, left_margin = 18px)
=#

if !@isdefined vr
    using Test
    using MechanicalUnits
    using Plots
    using MechGluePlots
    import Plots: default, px
    import RecipesBase
    import RecipesBase: debug
    using Plots

    # 'vector' real, quantity
    vr = range(1, 3; step = 0.2)
    vq = range(1, 3; step = 0.2)s
    # Function_range_domain
    f_r_r(t)           = sin(0.5∙2π∙t)     ∙ 9.81 
    f_q_q(t::Quantity) = sin(0.5∙2π∙t / s) ∙ 9.81N
    f_q_r(t::Quantity) = sin(0.5∙2π∙t /s)  ∙ 9.81
    f_r_q(t)           = sin(0.5∙2π∙t)     ∙ 9.81N

    s1x = range(-1, 1, length = 4)
    s1y = range(-1, 1, length = 4)
    s2x = range(1, -1, length = 4)
    s2y = range(-0.5, 0.5, length = 4)
end




# is_applicable can't tell if a quantity is acceptable or not.
# This is for cleaning the tests
function is_series_applicable(arg1, arg2)
    if arg1 isa Function && !isa(arg2, Function)
        try
            arg1(first(arg2))
            true
        catch
            false
        end
    elseif arg2 isa Function && !isa(arg1, Function)
        try
            arg2(first(arg1))
            true
        catch
            false
        end
    elseif arg1 isa Function && arg2 isa Function
        false   
    else
        true
    end
end


# plot one-dimensional 
oneseries = [vr, vq, f_r_r] # Not plotting quanity valued functions without input is acceptable
function test_one_serie(i, series; separate = true, kwargs...)
    label = string(series)
    if separate || i == 1
        #println("     $i new $label")
        global p = plot(series; label, kwargs...)
    else
        #println("     $i add $label")
        plot!(p, series; label, kwargs...)
    end
    @test typeof(p) <: Plots.Plot
    p
end
function test_one_series(oneseries; separate = true, kwargs...)
    for i in 1:length(oneseries)
        global p = test_one_serie(i, oneseries[i]; separate, kwargs...)
    end
    p
end


function test_two_axes(twoaxes; separate = true, kwargs...)
    for i in 1:length(twoaxes)
        series = twoaxes[i]
        label = if series[1] isa Function
            string(series[1]) * " - " * string(series[2])
        else
            string(series[2]) * " - " * string(series[1])
        end
        if separate || i == 1
            #println("     $i new $label")
            global p = plot(series[1], series[2]; label, kwargs...)  # Julia 1.3+
        else
            #println("     $i new $label")
            plot!(p, series[1], series[2]; label, kwargs...)  # Julia 1.3+
        end
        @test typeof(p) <: Plots.Plot
        p
    end
    p
end

#=
    abstract type PlSet end
    struct PlSetNotCat end
    struct PlR <: PlSet end # All numbers not a quantity
    struct PlQ <: PlSet end # All quantities
    # R², Z, etc not needed
    plset(x) = plset(typeof(x))
    function plset(::Type{T}) where T
        T <: Quantity ? PlQ() : PlR()
    end
    function plset(::Type{T}) where T <: AbstractArray{<:Union{Missing,<:Quantity}}
        @show T
        PlQ()
    end
    function plset(::Type{T}) where T <: AbstractArray{Missing}
        PlR()
    end
    function plset(::Type{Missing})
        PlR()
    end
    plset(1) == PlR()
    plset(1m) == PlQ()
    plset(missing) == PlR()
    plset([missing]) == PlR()
    plset([1m]) == PlQ()
    plset([missing, 1m]) == PlQ()

    abstract type PlFooRangeDomain end
    struct PlFNotCat <: PlFooRangeDomain end # A function we haven't found out about
    struct PlFRtoR <: PlFooRangeDomain end
    struct PlFRtoQ <: PlFooRangeDomain end
    struct PlFQtoR <: PlFooRangeDomain end
    struct PlFQto_Q <: PlFooRangeDomain end
    plfoorangedomain(::Type) = PlFNoCat()      # fall-back, any type we don't hit. Drop this?
    function plfoorangedomain(::Type{F}) where F <: Function
        return PlFNotCat  # fall-back, any function we don't recognize
    end

    plfoorangedomain(f::Function) = plfoorangedomain(typeof(f))
try_get_single_argtype(f::Function) = map(try_get_single_argtype, methods(f)) # check each method of function
try_get_single_argtype(mm::Method) = try_get_single_argtype(mm.sig)
try_get_single_argtype(x::Any) = nothing # Fail, return nothing to indicate failure.

# We are only intrested in doing things for the 1 argument signature.
# which is the 2-tuple
try_get_single_argtype(::Type{Tuple{F, T}}) where {F, T} = T
axisinputdomain = [try_get_single_argtype(a) for a in axisinput]
plset(axisinputdomain([1]))


    axisinputdomain = [plfoorangedomain(a) for a in axisinput]
=#

