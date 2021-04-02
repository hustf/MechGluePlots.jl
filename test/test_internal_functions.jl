include("test_func_defs.jl")

plempty = Plots.plot()

plotattributes = Dict{Symbol, Any}(:letter => :y)

vui = SeriesUnitInfo[]
vui  = accumulate_unit_info(vui, plotattributes, m, 1)
@test vui == [SeriesUnitInfo(1, m, nothing, :yguide, :y, nothing)]

vui = [ SeriesUnitInfo(  1  , m  ,nothing,      :xguide       ,  :x   , :scatter),
        SeriesUnitInfo(  2  , m² ,nothing,      :xguide       ,  :x   , :scatter),
        SeriesUnitInfo(  1  , s  ,nothing,      :yguide       ,  :y   ,nothing),
        SeriesUnitInfo(  2  , s² ,nothing,      :yguide       ,  :y   ,nothing)]

plotattributes = Dict{Symbol, Any}(:letter => :y, :series_plotindex => 1)
@test axis_units_bracketed(:x, vui) == "[m, m²]"
@test axis_units_bracketed(:y, vui) == "[s, s²]"
@test axis_units_bracketed(:z, vui) == "[]"
sertype(2, vui) == scatter
sertype(3, vui) == default(:seriestype)
print_prettyln(vui)
print_prettyln(plotattributes)