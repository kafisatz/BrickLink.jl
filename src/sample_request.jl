using BrickLink; import JSON3; import Random; import OAuth; import HTTP; import DataFrames
#https://www.bricklink.com/v3/api.page?page=auth

fldr = ENV["USERPROFILE"]
fi = joinpath(fldr,"auth.json")
@assert isfile(fi)
credentials = JSON3.read(fi)

#build request
di = Dict("type"=>"SET","no"=>"10030-1","new_or_used"=>"U","currency_code"=>"CHF") #U for used, N for new

df = get_prices(credentials,di)

#consider list of sets
pt = pathof(BrickLink)
fi = normpath(joinpath(pt,"..","ucs_list.txt"))
sets = CSV.read(fi,DataFrames.DataFrame,header=false)
DataFrames.rename!(sets,Dict(1=>"set_no"))


dfres = DataFrames.DataFrame()

for setno in sets.set_no
    setnostring = string(setno) * "-1"
    try
        di = Dict("type"=>"SET","no"=>setnostring,"new_or_used"=>"U","currency_code"=>"CHF") #U for used, N for new
        df = get_prices(credentials,di)
        println("Querying prices for set $setnostring ...")
        append!(dfres,df,cols=:union)
    catch e 
        println("Error querying prices for set $setnostring")
        @show e
    end
    
end

CSV.write(raw"C:\temp\prices.csv",dfres)