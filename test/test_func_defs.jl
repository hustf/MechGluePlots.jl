import Plots.px
using Test
using MechanicalUnits
using MechanicalUnits.Unitfu: DimensionError
using Plots
using MechGluePlots
using Plots: default, px
using RecipesBase
using RecipesBase: debug
using Plots
using MechGluePlots: accumulate_unit_info, sertype
using MechGluePlots: print_prettyln, SeriesUnitInfo

default(width = 5)

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

    s_1_down  = range(20, 6, length = 8)
    s_1_up = range(6, 20, length = 8)
    s_2_down = range(8, 1, length = 8)
    s_2_up =  range(1, 8, length = 8)

end
