# MechGluePlots
Plot recipes for Unitfu.jl, which is used by MechanicalUnits.jl.


This example shows the features. 
```
using MechanicalUnits
using Plots
using MechGluePlots
mxqm = hcat(s1x∙m, s2x∙m²)
myqm = hcat(s1y∙s, s2y∙s²)
plot(mxqm, myr, seriestype = [:path :scatter], label = ["path" "scatter"], xguide = "x", yguide = "y")
```
