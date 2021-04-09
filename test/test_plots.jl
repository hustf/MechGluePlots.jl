begin
    ispath("test") && cd("test")
    include("test_func_defs.jl")
    debug(false)
end
# plot one-dimensional
oneseries = [vr, vq, vq ∙ m, f_r_r, f_r_q]
plot(vq)
plot(vq; seriestype = :bar)
test_one_series(oneseries; seriestype = :scatter)
# This test uses plot! to modify. In this case, axis guide units
# are not cumulated, but units from the last plot! decides.
test_one_series(oneseries; separate = false)


# plot single series x vs y, unit placement
p = plot(vq, vq)
# When modifying a plot, the first unit is forgot
plot!(p, vq ∙ s, vq)
# Unit variation, same dimension
plot(vq |> ms, vq)

# functions, vectors
axisinput = [vr, vq, f_r_r, f_q_q, f_q_r, f_r_q]
twoaxes = [(arg1, arg2) for arg1 in axisinput, arg2 in axisinput if is_series_applicable(arg1, arg2)]
plot(twoaxes[2]...; label = "vr-vq")
p1 = test_two_axes(twoaxes)

# This uses plot modifications - the last units only are shown.
p2 = test_two_axes(twoaxes; separate = false)


function testplots(; args...)
    @testset verbose = true "1-1 One series" begin
        @testset "1-1-1 One axis" begin
            @testset "1-1-1-1 Unitless" begin
                plot(vr)
                plot(f_r_r)
                plot(f_r_r, xlims = (-2, 2))
            @test true;end
            @testset "1-1-1-2 Quantity" begin
                plot(vq)
                plot(f_r_q)
                plot(x-> f_q_q(x∙s))
                plot(f_q_q, xlims = (-2, 2)s)
            @test true;end
        end
        @testset "1-1-2 Two axis" begin
            @testset "1-1-2-1 Unitless" begin
                plot(s1x, s1y)
                plot(s1x, f_r_r)
                plot(f_r_r, s1x)
                p = plot(s1x, s1y, (x,y ) -> f_r_r(x - y)) # f creates a Surface, not shown
                @test p[1][1][:x][1] == s1x[1]
                @test p[1][1][:y][1]== s1y[1]
            end
            @testset "1-1-2-2 Quantity" begin
                plot(s1x∙m, s1y∙s)
                plot(s1x∙s, f_q_q)
                plot(f_q_q, s1x∙s)
                # Surfaces are type-checked to be Float64. User can create the surfaces on their own.
                @test_throws TypeError plot(s1x∙s, s1y∙s, (x,y ) -> f_q_q(x - y))
            end
        end
        @testset "1-1-3 Three axis" begin
            @testset "1-1-3-1 Unitless" begin
                plot(s1x, s1y, s1z)
                p = plot(f_r_r, s1y, s1z) # f(y)
                @test p[1][1][:x][1] == f_r_r(s1y[1])
                p = plot(s1x, f_r_r, s1z) # f(x)
                @test p[1][1][:y][1] == f_r_r(s1x[1])
            end
            @testset "1-1-3-2 Quantity" begin
                plot(s1x∙m, s1y∙s, s1z∙s)
                p = plot(f_q_q, s1y∙s, s1z∙s) # f(y)
                @test p[1][1][:x][1]N == f_q_q(s1y[1]∙s)
                p = plot(s1x∙s, f_q_q, s1z∙s)    # f(x)
                @test p[1][1][:y][1]N == f_q_q(s1x[1]∙s)
            end
        end
    end
    @testset verbose = true "1-2 Two series" begin
        @testset "1-2-1 One axis" begin
            @testset "1-2-1-1 Unitless" begin
                plot(mxr)
                # Lenient syntax
                plot([f_r_r  x->f_r_r(2x)], xlims =(-2,2))
                # Same plot
                plot([f_r_r, x->f_r_r(2x)], xlims =(-2,2))

            @test true;end
            @testset "1-2-1-2 Quantity" begin
                plot(mxq)
                # Lenient syntax
                plot([f_q_q  x->f_q_q(2x)], xlims =(-2,2)s, ylims = (-10,5)N)
                # Same plot
                plot([f_q_q, x->f_q_q(2x)], xlims =(-2,2)s, ylims = (-10,5)N)
            @test true;end
        end
        @testset "1-2-2 Two axis" begin
            @testset "1-2-2-1 Unitless" begin
                plot(mxr, myr)
                plot(mxr, [f_r_r, x-> 0.8f_r_r(1.25x)])
                plot([f_r_r , x-> 0.8f_r_r(1.25x)], myr)
                p = plot(hcat(1:0.1:2, 5:0.1:6), [f_r_r, x-> 0.8f_r_r(1.25x)])
                @test p[1][1][:y][1] == f_r_r(1)
                @test p[1][2][:y][1] == 0.8f_r_r(1.25 * 5)

            end
            @testset "1-2-2-2 Quantity" begin
                plot(mxq, myq)
                plot(myq, [f_q_q, x-> 0.8f_q_q(1.25x)])
                plot([f_q_q, x-> 0.8f_q_q(1.25x)], myq)
                # We can't dispatch on this without also dispatching on unitless function mappings, which we won't do.
                # An alternative would be type piracy on function expand_extrema!, which would be so bad.
                @test_throws DimensionError p = plot(hcat(1:0.1:2, 5:0.1:6), [f_r_q, x-> 0.8f_r_q(1.25x)], xlims = (0,7))
            end
        end
        @testset "1-2-3 Three axis" begin
            @testset "1-2-3-1 Unitless" begin
                plot(s1x, s1y, s1z)
                p = plot(f_r_r, s1y, s1z) # f(y)
                @test p[1][1][:x][1] == f_r_r(s1y[1])
                p = plot(s1x, f_r_r, s1z) # f(x)
                @test p[1][1][:y][1] == f_r_r(s1x[1])
            end
            @testset "1-2-3-2 Quantity" begin
                plot(s1x∙m, s1y∙s, s1z∙s)
                p = plot(f_q_q, s1y∙s, s1z∙s) # f(y)
                @test p[1][1][:x][1]N == f_q_q(s1y[1]∙s)
                p = plot(s1x∙s, f_q_q, s1z∙s)    # f(x)
                @test p[1][1][:y][1]N == f_q_q(s1x[1]∙s)
                # Surfaces are type-checked to be Float64. User can create the surfaces on their own.
                @test_throws TypeError plot(s1x∙s, s1y∙s, (x, y) -> f_q_q(x - y))
            end
        end
    end
end
@testset verbose = true "1 No frills          " begin
    testplots()
end
#TODO use defaults for consecutive tests. Perhaps output to io for inspection.


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

# Quantity plot with two series, conflicting units on one axis
plot(mxqm, myr)
plot(mxqm, myr, seriestype = [:path :scatter])
plot(mxqm, myr, seriestype = [:path :scatter], label = ["path" "scatter"])
plot(mxqm, myr, seriestype = [:path :scatter], label = ["path" "scatter"], xguide = "x", yguide = "y")

# Quantity plot with two series, conflicting units on two axes
plot(mxqm, myqm)
plot(mxqm, myqm, seriestype = [:path :scatter])
plot(mxqm, myqm, seriestype = [:path :scatter], label = ["path" "scatter"])
plot(mxqm, myqm, seriestype = [:path :scatter], label = ["path" "scatter"], xguide = "x", yguide = "y")


# Quantity plot with defined limits which already have units
plot(vr; ylims = (1.5, 2.5))
plot(vq; ylims = (1.5, 2.5)s)
plot(vq; xlims = (4,8), ylims = (1.5, 2.5)N)
plot(f_r_q; xlims = (0, 10), ylims = (-7.5, 5)N)
plot(f_q_q; xlims = (0, 10)s, ylims = (-7.5, 50)N, guidex = "-----------")
#plot(x-> (f_q_q(x), f_q_q(x)); xlims = (0, 10)s, ylims = (-7.5, 5)N)



# Unitless ribbons
plot(vr; ribbons = 2)
plot(f_r_r, -4:0.01:4; ribbons = 2)
plot(vr; ribbon = -0.5:0.5:5)
plot(f_r_r; ribbon = x-> 20 + 2f_r_r(2x / 3))

# Unitless ribbons, two series
plot(mxr; ribbons = [2 1])
plot([vr 0.25vr]; ribbon = [-0.15:0.15:0.15  -0.015:0.015:0.015])
plot(x->[f_r_r(x)   0.25f_r_r(x); ribbons = [2 1])



plot([f_r_r   x-> 0.25f_r_r(x)]; ribbons = [2 1]) # Not the best format, disregard

plot([f_r_r   x-> 0.25f_r_r(x)]; ribbon = x-> 20 + f_r_r(2x / 3)) # Can't give two ranges

plot((f_r_r   x-> 0.25f_r_r(x)), [(s1x, s1y), (s2x, s2y)]) # Can't give two ranges




# Quantity ribbons
plot(vq; ribbons = 2s)
plot(f_r_q; ribbons = 2N)
plot(vq; ribbon = (-0.5:0.5:5)s)
plot(f_r_q; ribbon = x-> 20N + 2f_r_q(2x / 3))

# Quantity ribbons, two series
plot(mxq; ribbons = [2 1]m)
#plot([f_r_q   x-> 0.25f_r_q(x)]; ribbons = [2 1]N)      # How to dispatch on this? Would be ok with given ranges.
plot([vq 0.25vq]; ribbon = [(-0.15:0.15:0.15)s  (-0.015:0.015:0.015)s])
plot([f_r_q   x-> 0.25f_r_q(x)])

# Acceptable failures:
plot([f_r_r   x-> 0.25f_r_r(x)]; ribbon = x-> 20 + f_r_r(2x / 3))
plot([f_r_q   x-> 0.25f_r_q(x)])


# Quantity ribbons, two series, mixed units
plot(mxqm; ribbons = [2m 1m²])
plot([f_r_r   x-> 0.25f_r_r(x)]; ribbons = [2 1])
plot([vr 0.25vr]; ribbon = [-0.15:0.15:0.15  -0.015:0.015:0.015])
plot([f_r_r   x-> 0.25f_r_r(x)]; ribbon = x-> 20 + f_r_r(2x / 3)) # Can't give two functions





plot(x-> m∙sin(x); ribbons = 0.2m)
plot(vr; ribbon = -0.5:0.5:5)
plot(vq; ribbon = range(-0.5s, 5s, step = 0.5s))
plot(f_q_q, vq)
plot(f_q_q, vq, ribbon = x-> N ∙ sqrt(x/s))


plot(f_r_q; ribbon = x-> N ∙ sqrt(x), xlims = (0, 10))


debug(true)


# Specified unit conversion


=#