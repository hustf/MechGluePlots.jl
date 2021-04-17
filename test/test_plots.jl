ispath("test") && cd("test")
include("test_func_defs.jl")

testplots() = testplot("No frills           1")
function testplots(pref::String)
    function fna(n)
        if Test.get_testset() isa Test.FallbackTestSet
            strip(pref) * " temp " * string(n)
        else
            strip(pref) * Test.get_testset().description * " " *string(n)
        end
    end
    function _png(n)
        title!(fna(n))
        isfile(fna(n)) && println("Writing over $(fna(n))")
        png(fna(n))
        # uncomment for interactive use:
        #current()
    end
    _png() = _png("")
    @testset verbose = true "-1 One series" begin
        @testset "-1-1 One axis" begin
            @testset "-1-1-1 Unitless" begin
                plot(vr)        ;_png()
                plot(f_r_r)      ;_png(1)
                plot(f_r_r, xlims = (-2, 2))           ;_png(2)
            @test true;end
            @testset "-1-1-2 Quantity" begin
                plot(vq, guide = "Units are postfixed:")           ; _png()
                plot(f_r_q)           ; _png(1)
                plot(x-> f_q_q(x∙s))           ;_png(2)
                plot(f_q_q, xlims = (-2, 2)s)           ;_png(3)
            @test true;end
        end
        @testset "-1-2 Two axis" begin
            @testset "-1-2-1 Unitless" begin
                plot(s1x, s1y)           ; _png()
                plot(s1x, f_r_r) ; _png(1)
                plot(f_r_r, s1x) ;_png(2)
                p = plot(s1x, s1y, (x,y ) -> f_r_r(x - y)) # f creates a Surface, not shown
               _png(3)
                @test p[1][1][:x][1] == s1x[1]
                @test p[1][1][:y][1]== s1y[1]
            end
            @testset "-1-2-2 Quantity" begin
                plot(s1x∙m, s1y∙s, xguide = "Units are postfixed:", yguide ="y axis") ; _png()
                plot(s1x∙s, f_q_q) ; _png(1)
                plot(f_q_q, s1x∙s) ;_png(2)
                # Surfaces are type-checked to be Float64. User can create the surfaces on their own.
                @test_throws TypeError plot(s1x∙s, s1y∙s, (x,y ) -> f_q_q(x - y))
            end
        end
        @testset "-1-3 Three axis" begin
            @testset "-1-3-1 Unitless" begin
                plot(s1x, s1y, s1z) ; _png()
                p = plot(f_r_r, s1y, s1z) # f(y)
                _png(1)
                @test p[1][1][:x][1] == f_r_r(s1y[1])
                p = plot(s1x, f_r_r, s1z) # f(x)
               _png(2)
                @test p[1][1][:y][1] == f_r_r(s1x[1])
            end
            @testset "-1-3-2 Quantity" begin
                plot(s1x∙m, s1y∙s, s1z∙s) ; _png()
                p = plot(f_q_q, s1y∙s, s1z∙s) # f(y)
                _png(1)
                @test p[1][1][:x][1]N == f_q_q(s1y[1]∙s)
               _png(2)
                p = plot(s1x∙s, f_q_q, s1z∙s)    # f(x)
               _png(3)
                @test p[1][1][:y][1]N == f_q_q(s1x[1]∙s)
            end
        end
    end
    @testset verbose = true "-2 Two series" begin
        @testset "-2-1 One axis" begin
            @testset "-2-1-1 Unitless" begin
                plot(mxr) ; _png()
                # Lenient syntax
                plot([f_r_r  x->f_r_r(2x)], xlims =(-2,2)) ; _png(1)
                # Same plot
                plot([f_r_r, x->f_r_r(2x)], xlims =(-2,2)) ;_png(2)

            @test true;end
            @testset "-2-1-2 Quantity" begin
                plot(mxq) ;_png()
                # Lenient syntax
                plot([f_q_q  x->f_q_q(2x)], xlims =(-2,2)s, ylims = (-10,5)N) ; _png(1)
                # Same plot
                plot([f_q_q, x->f_q_q(2x)], xlims =(-2,2)s, ylims = (-10,5)N) ;_png(2)

            @test true;end
        end
        @testset "-2-2 Two axis" begin
            @testset "-2-2-1 Unitless" begin
                plot(mxr, myr) ; _png()
                plot(mxr, [f_r_r, x-> 0.8f_r_r(1.25x)]) ;_png(2)
                plot([f_r_r , x-> 0.8f_r_r(1.25x)], myr) ;_png(3)
                p = plot(hcat(1:0.1:2, 5:0.1:6), [f_r_r, x-> 0.8f_r_r(1.25x)])
               _png(3)
                @test p[1][1][:y][1] == f_r_r(1)
                @test p[1][2][:y][1] == 0.8f_r_r(1.25 * 5)
            end
            @testset "-2-2-2 Quantity" begin
                plot(mxq, myq) ; _png()
                plot(myq, [f_q_q, x-> 0.8f_q_q(1.25x)]) ; _png(1)
                plot([f_q_q, x-> 0.8f_q_q(1.25x)], myq) ;_png(2)
                # We can't dispatch on this without also dispatching on unitless function mappings, which we won't do.
                # An alternative would be type piracy on function expand_extrema!, which would be so bad.
                @test_throws DimensionError p = plot(hcat(1:0.1:2, 5:0.1:6), [f_r_q, x-> 0.8f_r_q(1.25x)], xlims = (0,7))
            end
            @testset "-2-2-3 Quantity mixed units" begin
                plot(mxqm, myqm) ; _png()
                plot(myq, [f_q_q, x-> 0.8f_q_q(1.25x)∙m]) ; _png(1)
                plot([f_q_q, x-> 0.8f_q_q(1.25x)∙m], myq) ;_png(2)
                plot([x->f_q_q(x∙s/m), x-> 0.8f_q_q(1.25x∙s/m²)∙m], mxqm) ;_png(3)
                plot([x->f_q_q(x∙s/m)  x-> 0.8f_q_q(1.25x∙s/m²)∙m], mxqm,
                    xguide= "Load", 
                    yguide = "Response",
                    xlims = (0, 7.5),
                    ylims = (0,1),
                    framestyle = :origin) ;_png(4)
            end
        end
        @testset "-2-3 Three axis" begin
            @testset "-2-3-1 Unitless" begin
                plot(s1x, s1y, s1z) ; _png()
                p = plot(f_r_r, s1y, s1z) # f(y)
                _png(1)
                @test p[1][1][:x][1] == f_r_r(s1y[1])
                p = plot(s1x, f_r_r, s1z) # f(x)
               _png(2)
                @test p[1][1][:y][1] == f_r_r(s1x[1])
            end
            @testset "-2-3-2 Quantity" begin
                plot(s1x∙m, s1y∙s, s1z∙s) ; _png()
                p = plot(f_q_q, s1y∙s, s1z∙s) # f(y)
                _png(1)
                @test p[1][1][:x][1]N == f_q_q(s1y[1]∙s)
                p = plot(s1x∙s, f_q_q, s1z∙s)    # f(x)
               _png(2)
                @test p[1][1][:y][1]N == f_q_q(s1x[1]∙s)
                # Surfaces are type-checked to be Float64. User can create the surfaces on their own.
                @test_throws TypeError plot(s1x∙s, s1y∙s, (x, y) -> f_q_q(x - y))
            end
        end
    end
end


testplots_ribbons() = testplots_ribbon("Ribbon           1")
function testplots_ribbons(pref::String)
    function fna(n)
        if Test.get_testset() isa Test.FallbackTestSet
            strip(pref) * " temp " * string(n)
        else
            strip(pref) * Test.get_testset().description * " " *string(n)
        end
    end
    function _png(n)
        title!(fna(n))
        isfile(fna(n)) && println("Writing over $(fna(n))")
        png(fna(n))
        # uncomment for interactive use:
        current()
    end
    _png() = _png("")

    @testset verbose = true "-1 One series" begin
        @testset "-1-1 One axis" begin
            @testset "-1-1-1 Unitless" begin
                plot(vr, ribbon = 2)        ; _png()
                plot(f_r_r, ribbon = 2)      ; _png(1)
                plot(f_r_r, ribbon = x-> 20 + 2f_r_r(2x / 3)) ; _png(2)
                plot(vr, ribbon = -0.5:0.5:5)  ; _png(3)
                plot(f_r_r, ribbon = -0.5:0.5:5)  ; _png(4)
                plot(f_r_r, ribbon = (5:1:50, 5:-0.1:0.5))  ; _png(5)
            @test true;end
            @testset "-1-1-2 Quantity" begin
                plot(vq, ribbon = 2s)           ; _png()
                plot(f_r_q, ribbon = 2N)           ; _png(1)
                plot(f_r_q, ribbon = x-> 20N + 2f_r_q(2x / 3)); _png(2)
                plot(vq, ribbon = (-0.5:0.5:5)s)  ; _png(3)
                plot(f_r_q, ribbon = (-0.5:0.5:5)N)  ; _png(4)
                plot(f_r_q, ribbon = (5:1:50, 5:-0.1:0.5)N)  ; _png(5)
            @test true;end
        end
        @testset "-1-2 Two axis" begin
            @testset "-1-2-1 Unitless" begin
                plot(s1x, s1y, ribbon = 2)   ; _png()
                plot(s1x, f_r_r, ribbon = 2) ; _png(1)
                plot(f_r_r, s1x, ribbon = x-> 20 + 2f_r_r(2x / 3)) ; _png(2)
                plot(s1x, s1y, ribbon = -0.5:1.5:5) ; _png(3)
                plot(s1x, f_r_r, ribbon = -0.5:1.5:5) ; _png(4)
                plot(f_r_r, s1x, ribbon = (5:10:50, 5:-1:0.5)) ; _png(5)
                plot(xlims =(-5, 5), f_r_r, ribbon = x-> 1.25 * f_r_r(x)); _png(6)
            @test true;end
            @testset "-1-2-2 Quantity" begin
                plot(s1x∙m, s1y∙m, ribbon = 2.0m)   ; _png()
                plot(s1x∙s, f_q_q, ribbon = 2N) ; _png(1)
                plot(f_q_q, s1x∙s, ribbon = x-> 20N + 2f_q_q(2x / 3)) ; _png(2)
                plot(s1x∙s, s1y∙N, ribbon = (-0.5:1.5:5)N) ; _png(3)
                plot(s1x∙s, f_q_q, ribbon = (-0.5:1.5:5)N) ; _png(4)
                plot(f_q_q, s1x∙s, ribbon = (5:10:50, 5:-1:0.5)N) ; _png(5)
                plot(xlims =(-5s, 5s), f_q_q, ribbon = x-> 1.25 * f_q_q(x)); _png(6)
            @test true;end
        end
    end
    @testset verbose = true "-2 Two series" begin
        @testset "-2-1 One axis" begin
            @testset "-2-1-1 Unitless" begin
                plot(mxr, ribbon = [2 1]) ; _png()
                plot(mxr, ribbon = [2 1; 1 0.5 ; 0.5 0.25; 0.03 0.1]) ; _png(1)
                plot([f_r_r  x-> f_r_r(0.5x)], ribbon = [-1.5:0.15:1.15  -3.0:0.30:2.3 ]) ; _png(2)
                plot([f_r_r  x-> f_r_r(0.5x)], ribbon = ([-15:1.5:11.5  -3.0:0.30:2.3 ], [-1.5:0.15:1.15  -15:1.5:11.5  ])) ; _png(3)
                plot([f_r_r  x-> f_r_r(0.5x)], ribbon = x-> 0.2f_r_r(x)) ; _png(4)
                plot([f_r_r, x-> f_r_r(0.5x)], ribbon = [x-> 0.1f_r_r(x), x-> 0.5f_r_r(x)]) ; _png(5)
            @test true;end
            @testset "-2-1-2 Quantity" begin
                plot(mxq, ribbon = [2.0 1.0]m) ; _png()
                plot(mxq, ribbon = [2 1; 1 0.5 ; 0.5 0.25; 0.03 0.1]m) ; _png(1)
                # With unknown abscissa, it is harder to implement unit conversions without
                # also affecting other types of plots.
                #plot(mxq, ribbon = [x-> m(f_r_q(x) / (1kg / s²))   x-> m(f_r_q(x) / (1kg / s²))]) ; _png(1)
                # We can't dispatch on the below without also dispatching on unitless function mappings, which we won't do.
                #plot([f_r_q  x-> f_r_q(0.5x)], ribbon = [-1.5:0.15:1.15  -3.0:0.30:2.3 ]N, xlims = (-3.0, 3.0)) ; _png(2)
                #plot([f_r_q  x-> f_r_q(0.5x)], ribbon = ([-15:1.5:11.5  -3.0:0.30:2.3 ]N, [-1.5:0.15:1.15  -15:1.5:11.5  ]N)) ; _png(3)
                #plot([f_r_q  x-> f_r_q(0.5x)], ribbon = x-> 0.2f_r_q(x)) ; _png(4)
                #plot([f_r_q, x-> f_r_q(0.5x)], ribbon = [x-> 0.1f_r_q(x), x-> 0.5f_r_q(x)]) ; _png(5)
            @test true;end
        end
        @testset "-2-2 Two axis" begin
            @testset "-2-2-1 Unitless" begin
                plot(mxr, myr, ribbon = [2 1]) ; _png()
                plot(mxr, [f_r_r, x-> 0.8f_r_r(1.25x)], ribbon = [2 1; 1 0.5 ; 0.5 0.25; 0.03 0.1]) ; _png(1)
                plot([f_r_r , x-> 0.8f_r_r(1.25x)], myr, ribbon = [1.5:-0.55:-1.15  15:-5.5:-11.5 ]) ; _png(2)
                p = plot(hcat(1:0.1:3, 3:0.1:5),
                    [f_r_r, x-> 0.8f_r_r(1.25x)],
                    ribbon = ([s_1_down  s_2_down], [s_1_up  s_2_up]),
                    labels = ["s_1" "s_2"])
                _png(3)
                @test p[1][1][:y][1] == f_r_r(1)
                @test p[1][2][:y][1] == 0.8f_r_r(1.25 * 3)
                plot( xlims =(-5, 5), [f_r_r, x-> 0.5f_r_r(1.5x)], 
                        ribbon = [x-> f_r_r(0.25x), x-> f_r_r(0.5x)]); _png(4)
                plot( xlims =(-5, 5), [f_r_r, x-> 0.5f_r_r(1.5x)], 
                        ribbon = ([r1d  r2d], [r1u  r2u])) ; _png(5)

            end
            @testset "-2-2-2 Quantity" begin
                plot(mxq, myq, ribbon = [2 1]s) ; _png()
                plot(mxq, [x->f_q_q(x∙s/m), x-> 0.8f_q_q(1.25x∙s/m)], ribbon = [2 1; 1 0.5 ; 0.5 0.25; 0.03 0.1]N) ; _png(1)
                plot([x-> f_q_q(x) , x-> 0.8f_q_q(1.25x)], myq, ribbon = [1.5:-0.55:-1.15  15:-5.5:-11.5 ]s) ; _png(2)
                p = plot(hcat(1:0.1:3, 3:0.1:5)s,
                    [f_q_q, x-> 0.8f_q_q(1.25x)],
                    ribbon = ([s_1_down  s_2_down]N, [s_1_up  s_2_up]N),
                    labels = ["s_1" "s_2"])
                _png(3)
                @test p[1][1][:y][1]N == f_q_q(1s)
                @test p[1][2][:y][1]N == 0.8f_q_q(1.25 * 3s)
                # We can't dispatch on this without also dispatching on unitless function mappings, which we won't do.
                @test_throws DimensionError p = plot(hcat(1:0.1:2, 5:0.1:6), [f_r_q, x-> 0.8f_r_q(1.25x)], xlims = (0,7))
                plot( xlims =(-5s, 5s), [f_q_q, x-> 0.5f_q_q(1.5x)],
                     ribbon = [x-> f_q_q(0.25x), x-> f_q_q(0.5x)]); _png(4)
            end
            @testset "-2-2-3 Quantity mixed units" begin
                plot(mxqm, myqm, ribbon = [2s 1s²], xguide = "Several units, postfixed:", yguide = "Other units, postfixed:") ; _png()
                plot(myq, [f_q_q, x-> 0.8f_q_q(1.25x)∙m], ribbon = [2N 1N∙m]) ; _png(1)
                plot([f_q_q, x-> 0.8f_q_q(1.25x)∙m], myq, ribbon = [2 1]s) ; _png(2)
                p = plot(hcat(1:0.1:3, 3:0.1:5)s,
                    [f_q_q, x-> 0.8f_q_q(1.25x)],
                    ribbon = ([s_1_down  s_2_down]N, [s_1_up  s_2_up]N),
                    labels = ["s_1" "s_2"])
                @test p[1][1][:y][1]N == f_q_q(1s)
                @test p[1][2][:y][1]N == 0.8f_q_q(1.25 * 3s)
                plot(myq, [f_q_q, x-> 0.8f_q_q(1.25x)∙m],  ribbon = [2N 1N∙m]) ; _png(2)
                plot([x->f_q_q(x∙s/m), x-> 0.8f_q_q(1.25x∙s/m²)], mxqm, 
                    ribbon = ([s_1_down∙m s_2_down∙m²], [s_1_up∙m  s_2_up∙m²])) ;_png(3)
                plot( xlims =(-5s, 5s), [f_q_q, x-> 0.5f_q_q(1.5x)∙m],
                    ribbon = [x-> f_q_q(0.25x), x-> 0.5∙f_q_q(0.5x)∙m],
                    yguide = "Load", xguide = "Time"); _png(4)

                plot( xlims =(-5s, 5s), 
                     [f_q_q  x-> 0.5f_q_q(1.5x)∙m],
                    ribbon = ([s_1_down∙N  s_2_down∙N∙m], [s_1_up∙N   s_2_up∙N∙m]),
                    yguide = "Load", xguide = "Time"); _png(5)
                f1d(x) = f_q_q(0.25x)
                f2d(x) = f_q_q(0.25x)∙m
                f1u(x) = 0.5∙f_q_q(0.5x)
                f2u(x) = 0.5∙f_q_q(0.5x)∙m

                plot(hcat(1:0.1:3, 3:0.1:5)s,
                    [f_q_q, x-> 0.8f_q_q(1.25x)∙m],
                    ribbon = ([f1d,   f2d], [f1u, f2u]),
                                        labels = ["s_1" "s_2"])
            @test true;end
        end
    end
end

@testset verbose = true "No frills           1" begin
    testplots(Test.get_testset().description)
end
@testset verbose = true "Ribbons             2" begin
    testplots_ribbons(Test.get_testset().description)
end
# Further tests: Set additional parameters with Plots.default(...)