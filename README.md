# MechGluePlots
[Plots.jl]() recipes for [Unitfu.jl](https://github.com/hustf/Unitfu.jl), from registy [M8](https://github.com/hustf/M8). There is a small ecosystem for glue code between Unitfu.jl and other packages.

This package enables all plots possible with Plots.jl - but now with quantities instead of unitless numbers. Many (or most?) specialized plots will also work with units, since this plugs into the plotting pipeline at the base level, and plays by all the rules.

It is customary to show forces differently from torques or positions, and you can - that's an advantage of working with quantities instead of just numbers. But this package simply provides the most general foundation for plugging into Plots.jl. When you specialize on quantities, import this package.

This example shows how mixed units are automatically added to axis guides. 
```
]registry add https://github.com/hustf/M8
using MechanicalUnits
using Plots
using MechGluePlots
f_q_q(t) = sin(0.3∙2π∙t / s) ∙ 9.81N

plot(xlims = (-5, 5)s, 
    [f_q_q, t -> 0.5f_q_q(1.5t)∙m],
    ribbon = [x-> f_q_q(0.25x), x-> 0.5∙f_q_q(0.5x)∙m],
    yguide = "Load", xguide = "Time")
```
![mixed_units_example.png](/images/mixed_units_example.png)

There are no changes at all to Plot.jl's interface - just know that surfaces and volumes are defined as unitless. The test folder includes all the relevant syntax with and without quantities.

Debug info is output to the terminal if you call `RecipesBase.debug(true)`.

# Very technical
The details below are for future reference - it took some time to understand the recipes pipeline.

## Recipes pipeline, before adding units
The pipeline which we hook into is described in Plots.jl, RecipesBase.jl and RecipesPipeline.jl.
Details matter if you want to make additional recipes-

Here's how it works in one typical case - the plot is shown below:
```
f(x) = 2sin(2π * x)
s_1_down  = range(20, 6, length = 8)
s_1_up = range(6, 20, length = 8)
s_2_down = range(8, 1, length = 8)
s_2_up =  range(1, 8, length = 8)


plot(hcat(1:0.1:3, 4:0.1:6),
                    [f, x-> 0.5f(2x)],
                    ribbon = ([s_1_down  s_2_down], [s_1_up  s_2_up]),
                    labels = ["s_1" "s_2"],
                    xguide = "Time",
                    yguide = "Force")
```
![unitless_pipeline.png](/images/unitless_pipeline.png)
This shows how the recipe pipeline worked in this case:
<pre><code>
      Process user and type recipes, length(args) = 2
        _process_userrecipes, length(still_to_process) = 1
              Fallback user recipe (x, y)
                Type recipe <: AbstractArray y, type Vector{Function}: preprocess_axis_args!
                Type recipe <: AbstractArray y, type Vector{Function}: Try type toplevel.
                Type recipe: No type change, recursively try Type recipe <: AbstractArraywith first element:
                Type recipe <: AbstractArray y, type Vector{Function}: postprocess_axis_args!
                Type recipe: Received values from first element of type Vector{Function}. 
                , which we'll return to the caller. The rest is dropped.
              Fallback user recipe: did_replace = false
        Returned from applying user recipe, added to start of queue: length(rd_list) = 1
        _process_userrecipes, length(still_to_process) = 1
        Returned from applying user recipe, added to start of queue: length(rd_list) = 2
        _process_userrecipes, length(still_to_process) = 2
        _finish_userrecipe!
        _process_userrecipes, length(still_to_process) = 1
        _finish_userrecipe!
        <-Exiting _process_userrecipes: length(kw_list) = 2
      User and type recipes returned, length(kw_list) = 2
      typeof(kw_list) = Vector{Dict{Symbol, Any}}
      Process plotrecipes:
        _process_plotrecipes, length(still_to_process) = 2
        _process_plotrecipes, length(still_to_process) = 1
        <-Exiting _process_plotrecipes: length(kw_list) = 2
      Plot recipes returned, length(kw_list) = 2
      typeof(kw_list) = Vector{Dict{Symbol, Any}}
      Process plot / subplot / layout setup
      Plot_setup returned, length(kw_list) = 2
      plot_setup finished, process series recipes:
      series recipes finished, length(kw_list) = 2
</code></pre>

## Pipeline with quantities
We modify the example above slightly to include units. Most of the time, the multiplication character '*' is not necessary, but when it is, we prefer to use '∙', simply because of readability. See ['MechanicalUnits.jl'](https://github.com/hustf/MechanicalUnits.jl).
```
fq(t) = 2sin(2π∙t / s)N
plot(hcat((1:0.1:3)s, (4:0.1:6)s),
                    [fq, t-> 0.5fq(2t)],
                    ribbon = ([s_1_down  s_2_down]N, [s_1_up  s_2_up]N),
                    labels = ["s_1" "s_2"],
                    xguide = "Time",
                    yguide = "Force")
```
![unitless_pipeline.png](/images/quantities_pipeline.png)

This shows how the recipe pipeline worked with quantities - additions in bold:
<pre><code>
      Process user and type recipes, length(args) = 2
        _process_userrecipes, length(still_to_process) = 1
    <b>MechGluePlots  where {F<:Function, T <: AbstractArray{<:Union{Missing,<:Quantity}}}</b>
        Returned from applying user recipe, added to start of queue: length(rd_list) = 2
        _process_userrecipes, length(still_to_process) = 2

        <b>MechGluePlots x::T, foo::F) where {F<:Function, T<:AbstractArray{<:Union{Missing,<:Quantity}}}</b>
        Returned from applying user recipe, added to start of queue: length(rd_list) = 1
        _process_userrecipes, length(still_to_process) = 2
              Fallback user recipe (x, y)
                Type recipe <: AbstractArray x, type Vector{Quantity{Float64,  ᵀ...: preprocess_axis_args!
                Type recipe <: AbstractArray x, type Vector{Quantity{Float64,  ᵀ...: Try type toplevel.

        <b>MechGluePlots ::Type{T}, x::T) where T <: AbstractArray{<:Union{Missing,<:Quantity}}</b>
                Type recipe, letter x, type Vector{Quantity{Float64,  ᵀ...: Received w, size (21,).
                   type Vector{Float64}
                Type recipe <: AbstractArray x, type Vector{Quantity{Float64,  ᵀ...: postprocess_axis_args!
                Type recipe <: AbstractArray y, type Vector{Quantity{Float64,  ᴸ...: preprocess_axis_args!
                Type recipe <: AbstractArray y, type Vector{Quantity{Float64,  ᴸ...: Try type toplevel.

        <b>MechGluePlots ::Type{T}, x::T) where T <: AbstractArray{<:Union{Missing,<:Quantity}}</b>   
                Type recipe, letter y, type Vector{Quantity{Float64,  ᴸ...: Received w, size (21,).
                   type Vector{Float64}
                Type recipe <: AbstractArray y, type Vector{Quantity{Float64,  ᴸ...: postprocess_axis_args!
              Fallback user recipe: did_replace = true
        Returned from applying user recipe, added to start of queue: length(rd_list) = 1
        _process_userrecipes, length(still_to_process) = 2
              Fallback user recipe (x, y)
              Fallback user recipe: did_replace = false
        Returned from applying user recipe, added to start of queue: length(rd_list) = 1
        _process_userrecipes, length(still_to_process) = 2
        Returned from applying user recipe, added to start of queue: length(rd_list) = 1
        _process_userrecipes, length(still_to_process) = 2
        _finish_userrecipe!
        _process_userrecipes, length(still_to_process) = 1

        <b>MechGluePlots x::T, foo::F) where {F<:Function, T<:AbstractArray{<:Union{Missing,<:Quantity}}}</b>
        Returned from applying user recipe, added to start of queue: length(rd_list) = 1
        _process_userrecipes, length(still_to_process) = 1
              Fallback user recipe (x, y)
                Type recipe <: AbstractArray x, type Vector{Quantity{Float64,  ᵀ...: preprocess_axis_args!
                Type recipe <: AbstractArray x, type Vector{Quantity{Float64,  ᵀ...: Try type toplevel.

        <b>MechGluePlots ::Type{T}, x::T) where T <: AbstractArray{<:Union{Missing,<:Quantity}}</b>   
                Type recipe, letter x, type Vector{Quantity{Float64,  ᵀ...: Received w, size (21,).
                   type Vector{Float64}
                Type recipe <: AbstractArray x, type Vector{Quantity{Float64,  ᵀ...: postprocess_axis_args!
                Type recipe <: AbstractArray y, type Vector{Quantity{Float64,  ᴸ...: preprocess_axis_args!
                  Type recipe <: AbstractArray y, type Vector{Quantity{Float64,  ᴸ...: Try type toplevel.

        <b>MechGluePlots ::Type{T}, x::T) where T <: AbstractArray{<:Union{Missing,<:Quantity}}</b>   
                Type recipe, letter y, type Vector{Quantity{Float64,  ᴸ...: Received w, size (21,).
                   type Vector{Float64}
                Type recipe <: AbstractArray y, type Vector{Quantity{Float64,  ᴸ...: postprocess_axis_args!
              Fallback user recipe: did_replace = true
        Returned from applying user recipe, added to start of queue: length(rd_list) = 1
        _process_userrecipes, length(still_to_process) = 1
              Fallback user recipe (x, y)
              Fallback user recipe: did_replace = false
        Returned from applying user recipe, added to start of queue: length(rd_list) = 1
        _process_userrecipes, length(still_to_process) = 1
        Returned from applying user recipe, added to start of queue: length(rd_list) = 1
        _process_userrecipes, length(still_to_process) = 1
        _finish_userrecipe!
        <-Exiting _process_userrecipes: length(kw_list) = 2
      User and type recipes returned, length(kw_list) = 2
      typeof(kw_list) = Vector{Dict{Symbol, Any}}
      Process plotrecipes:
        _process_plotrecipes, length(still_to_process) = 2

        <b>MechGluePlots ::Type{Val{:postfixseries}}, plt)</b>
        _process_plotrecipes, length(still_to_process) = 2

        <b>MechGluePlots ::Type{Val{:postfixseries}}, plt)</b>
        _process_plotrecipes, length(still_to_process) = 2
        _process_plotrecipes, length(still_to_process) = 1
        <-Exiting _process_plotrecipes: length(kw_list) = 2
      Plot recipes returned, length(kw_list) = 2
      typeof(kw_list) = Vector{Dict{Symbol, Any}}
      Process plot / subplot / layout setup
      Plot_setup returned, length(kw_list) = 2
      plot_setup finished, process series recipes:
      series recipes finished, length(kw_list) = 2
</code></pre>
