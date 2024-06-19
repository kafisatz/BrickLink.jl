using BrickLink;import CSV; using DataFrames; using JSON3

#list of sets
pt = pathof(BrickLink)
fi = normpath(joinpath(pt,"..","ucs_list.txt"))
sets = CSV.read(fi,DataFrames.DataFrame,header=false)
DataFrames.rename!(sets,Dict(1=>"set_no"))

#credentials
fldr = ENV["USERPROFILE"]
fi = joinpath(fldr,"auth.json")
@assert isfile(fi)
credentials = JSON3.read(fi);

#request prices from BrickLink API
dfres = DataFrames.DataFrame()

#test
setno = sets.set_no[1]
setnostring = string(setno) * "-1"
di = Dict("type"=>"SET","no"=>setnostring,"new_or_used"=>"U","currency_code"=>"CHF") #U for used, N for new
dftest = get_prices(credentials,di)
        
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

