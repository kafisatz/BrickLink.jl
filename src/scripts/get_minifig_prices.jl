using Revise; using BrickLink;import CSV; using DataFrames; using JSON3; using HTTP; using OAuth
#credentials
fldr = ENV["USERPROFILE"]; fi = joinpath(fldr,"auth.json"); @assert isfile(fi)
credentials = JSON3.read(fi);

#test if current IP has access
#https://www.bricklink.com/v2/api/register_consumer.page
mf = get_minifigs("75397-1",credentials); @assert size(mf,1) >5

#get minifig list
mf = CSV.read(joinpath(ENV["USERPROFILE"],"OneDrive - K","Dateien","Lego","BrickLink","minifigs.csv"),DataFrame)

mfuq = convert(Vector{String},sort(unique(mf.minifig)))

setnostring ="sw0346" #setnostring ="sw0586"
di = Dict("type"=>"MINIFIG","no"=>setnostring,"new_or_used"=>"U","currency_code"=>"CHF") #U for used, N for new
di_new = deepcopy(di)
di_new["new_or_used"] = "N"

@warn("if this fails make sure that your ip is added here: \nhttps://www.bricklink.com/v2/api/register_consumer.page")
dftest = get_prices(credentials,di)

#used
@time mf_used = get_prices(credentials,di,mfuq)

CSV.write(joinpath(ENV["USERPROFILE"],"OneDrive - K","Dateien","Lego","BrickLink","minifig_prices_used.csv"),mf_used)

#new
@time mf_new = get_prices(credentials,di_new,mfuq)

CSV.write(joinpath(ENV["USERPROFILE"],"OneDrive - K","Dateien","Lego","BrickLink","minifig_prices_new.csv"),mf_new)