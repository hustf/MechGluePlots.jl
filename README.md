# MechGluePlots
Plot recipes for Unitfu.jl, which is used by MechanicalUnits.jl. Registry: M8.


This example shows the most interesting features. 
```
using MechanicalUnits
using Plots
using MechGluePlots
    s1x = [1.0,2,3]
    s2x = [1.0,2,3.5]
    s1y = [1.0,2,4]
    s2y = [1.0,2,2]
    mxqm = hcat(s1x∙m, s2x∙m²)
    myqm = hcat(s1y∙s, s2y∙s²)
    plot(mxqm, myqm, seriestype = [:path :scatter], label = ["path" "scatter"], xguide = "x", yguide = "y")
```
Plotting functions with quanity range or domain is also working, though not fully tested.
Debug info is output if you call 'RecipesBase.debug(true)'.
