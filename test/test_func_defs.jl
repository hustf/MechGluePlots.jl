#=  Smaller size plots
default(titlefont = (20, "times"), legendfontsize = 26, 
    guidefont = (30, :darkgreen), tickfont = (24, :orange), 
    framestyle = :origin, minorgrid = true,
    legend = :topleft, linewidth = 4,
    bottom_margin = 18px, left_margin = 18px)
=#
using Test
using MechanicalUnits
import MechanicalUnits.Unitfu.DimensionError
using Plots
using MechGluePlots
import Plots: default
import RecipesBase
import RecipesBase: debug
using Plots
import MechGluePlots: accumulate_unit_info, axis_units_bracketed, sertype
import MechGluePlots: print_prettyln, SeriesUnitInfo
if !@isdefined vq
    # 'vector' real, quantity
    vr = range(1, 3; step = 0.2)
    vq = range(1, 3; step = 0.2)s
    # Function_range_domain
    f_r_r(t)           = sin(0.3∙2π∙t)     ∙ 9.81 
    f_q_q(t::Quantity) = sin(0.3∙2π∙t / s) ∙ 9.81N
    f_q_r(t::Quantity) = sin(0.3∙2π∙t / s)  ∙ 9.81
    f_r_q(t)           = sin(0.3∙2π∙t)     ∙ 9.81N

    s1x = range(-1, 1, length = 4)
    s1y = [-0.75, -0., 0.2, 1.0]
    s1z = s1x + s1y
    s2x = range(0.9, -0.9, length = 4)
    s2y = [-0.5, -0.1, 0.3, 0.5]
    s2z = s2x + s2y

    mxr = hcat(s1x, s2x)
    myr = hcat(s1y, s2y)
    mxq = hcat(s1x∙m, s2x∙m)
    myq = hcat(s1y∙s, s2y∙s)
    mxqm = hcat(s1x∙m, s2x∙m²)
    myqm = hcat(s1y∙s, s2y∙s²)

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
                println("     $i new $label")
                global p = plot(series[1], series[2]; label, kwargs...)  # Julia 1.3+
            else
                println("     $i new $label")
                plot!(p, series[1], series[2]; label, kwargs...)  # Julia 1.3+
            end
            @test typeof(p) <: Plots.Plot
            p
        end
        p
    end

end
