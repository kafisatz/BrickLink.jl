using Revise; using BrickLink;import CSV; using DataFrames; using JSON3; using HTTP; using OAuth

#list of sets
pt = pathof(BrickLink)
fi = normpath(joinpath(pt,"..","set_list.txt"))
sets = CSV.read(fi,DataFrames.DataFrame,header=false)
DataFrames.rename!(sets,Dict(1=>"set_no"));

#credentials
fldr = ENV["USERPROFILE"]
fi = joinpath(fldr,"auth.json")
@assert isfile(fi)
credentials = JSON3.read(fi);

#test
setno = 75098
setno = sets.set_no[1]
setnostring = string(setno) * "-1"
di = Dict("type"=>"SET","no"=>setnostring,"new_or_used"=>"U","currency_code"=>"CHF") #U for used, N for new
di_new = deepcopy(di)
di_new["new_or_used"] = "N"

dftest = get_prices(credentials,di)
dftest = get_prices(credentials,di_new)

#used
@time df_used = get_prices(credentials,di,sets)

#new prices
@time df_new = get_prices(credentials,di_new,sets)

#download images
imgfldr = raw"C:\Users\bernhard.koenig\OneDrive - K\Dateien\Lego\starwars_bricklink_images"
@assert isdir(imgfldr)
download_images(df_used,imgfldr)

CSV.write(raw"C:\temp\prices_used.csv",df_used)
CSV.write(raw"C:\temp\prices_new.csv",df_new)