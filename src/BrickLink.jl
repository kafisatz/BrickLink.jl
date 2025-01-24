module BrickLink

export EXCHANGE_RATES_DICT_GLOBAL 
global EXCHANGE_RATES_DICT_GLOBAL = Dict{String,Float64}()

using StatsBase
using Dates 
import OAuth
import JSON3
import Random
import OAuth
import HTTP
import CSV

using Folds
using DataFrames
using ProgressMeter
using InfluxDBClient

include("prices.jl")
include("download.jl")
include("main.jl")
include("influxdb.jl")
include("minifigs.jl")

include("get_item_id.jl")
include("get_prices_and_stores.jl")

include("common.jl")
include("json.jl")
include("fxrate.jl")

end
