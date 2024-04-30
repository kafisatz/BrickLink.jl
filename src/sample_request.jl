using BrickLink; import JSON3; import Random; import OAuth; import HTTP; import DataFrames
#https://www.bricklink.com/v3/api.page?page=auth

fldr = ENV["USERPROFILE"]
fi = joinpath(fldr,"auth.json")
@assert isfile(fi)
credentials = JSON3.read(fi)

#build request
di = Dict("type"=>"SET","no"=>"10030-1","new_or_used"=>"U","currency_code"=>"CHF") #U for used, N for new

df = get_prices(credentials,di)