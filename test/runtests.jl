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

# Unitful plot with defined limits which already have units

plot(vr; xlims = (4,8), ylims = (1.5, 2.5))
plot(vq; xlims = (4,8), ylims = (1.5, 2.5)s)

