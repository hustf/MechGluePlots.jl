include("test_func_defs.jl")
include("test_internal_functions.jl")
include("test_apply_recipe.jl")

# plot one-dimensional 
oneseries = [vr, vq, f_r_r, f_r_q]
plot(vq)
plot(vq; seriestype = :bar)
test_one_series(oneseries; seriestype = :scatter)
# This test uses plot! to modify
test_one_series(oneseries; separate = false)


# plot single series x vs y, unit placement
p = plot(vq, vq)
# The first unit is forgot
plot!(p, vq * s, vq)
# Unit variation, same dimension
plot(vq |> ms, vq)

# functions, vectors
axisinput = [vr, vq, f_r_r, f_q_q, f_q_r, f_r_q]
twoaxes = [(arg1, arg2) for arg1 in axisinput, arg2 in axisinput if is_series_applicable(arg1, arg2)]
plot(twoaxes[2]...; label = "vr-vq")
p1 = test_two_axes(twoaxes)
# This uses plot modifications - the last units only are shown.
p2 = test_two_axes(twoaxes; separate = false)


# Multiple series, plot without modifying

# A unitless plot with two series 
# (not recommended, we don't aim to make units work with this method)
plot([(s1x, s1y), (s2x, s2y)])

# In the recommended format, matrices with each column one series
plot(mxr, myr)
plot(mxr, myr, seriestype = [:path :scatter])
plot(mxr, myr, seriestype = [:path :scatter], xguide = "x", yguide = "y")

# Quantity plot, two series, same units each axis
plot(mxq, myq)

# Unitful plot with two series, conflicting units on one axis
plot(mxqm, myr)
plot(mxqm, myr, seriestype = [:path :scatter])
plot(mxqm, myr, seriestype = [:path :scatter], label = ["path" "scatter"])
plot(mxqm, myr, seriestype = [:path :scatter], label = ["path" "scatter"], xguide = "x", yguide = "y")














# subplots


# plot complex-valued function, rational range
# There are no default recipes for this. Some 
# would prefer a vector plotted from points one axis,
# but plotting the value at points is just as reasonable.
# So this is left to the user

# plot complex-valued function, complex range
# There are no default recipes for this, and lots of options
# So this is left to the user

#=
# 3d scatter with different units on all axes, adapted from Plots examples
n = 100
θs = range(0, stop = 8π, length = n)
x = θs * N .* map(cos, θs)
y = (0.1θs) * N .* map(sin, θs) .|> N
z = (1:n)s

p = plot(x, y, z,
         zcolor = reverse(z./s), 
         m = (10, 0.8, :blues, Plots.stroke(0)), 
         leg = false, cbar = true, w = 5,
         zguide = "Time") # Can't display yet, triggers error.
se = p.series_list[1]
se.plotattributes[:marker_z]
p
=#
#@test typeof(p) <: Plots.Plot
#plot!(p, zeros(n), zeros(n), 1:n, w = 10);

#=
# Function_range_domain
f_r_z(t::Real)      = exp(0.5∙2π∙t∙im)∙ 9.81 
#f_q_qz(t::Quantity) = sin(0.5∙2π∙t / s) ∙ 9.81N
#f_q_z(t::Quantity)  = sin(0.5∙2π∙t /s)  ∙ 9.81
#f_r_qz(t)           = sin(0.5∙2π∙t)     ∙ 9.81N

vz = f_r_z.(vr)
#axisinput = [vr, vq, f_r_r, f_q_q, f_q_r, f_r_q]
axisinput = [vr, vz, f_r_z]
plot(vz, vr)
plot(vz, vz .+1)

twoaxes = [(arg1, arg2) for arg1 in axisinput, arg2 in axisinput if is_series_applicable(arg1, arg2)]

test_two_axes(twoaxes)


=#


# Add a series to an existing plot - but now with existing axes.
# There should have been a warning, but we can't access the existing label.
# So it is overwritten without warning, which is not nice.
p3 = plot(f_q_q.(vq), vq)
plot!(p3, vq, f_q_q.(vq))






#RecipesBase.debug(true)
#plot([(s1x∙m, s1y∙m), (s2x∙s, s2y∙s)])

plot(s1x, rand(4, 2))
plot(s1x∙m, rand(4, 2))
plot(s1x∙m, rand(4, 2)s, label = "LAB")
s1y





#=)
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

