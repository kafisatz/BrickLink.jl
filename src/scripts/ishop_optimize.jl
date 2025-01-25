using BrickLink;using StatsBase
using JuMP;import CSV;using DataFrames;import HiGHS

ctryfi = normpath(joinpath(pathof(BrickLink),"..","..","data","country_to_continent.csv"))
@assert isfile(ctryfi)
countryToContinentDict = countrydict(ctryfi);

@info("run ishop_fetch_data.jl to generate the data.")
data = CSV.read(raw"c:\temp\dfsupply.csv",DataFrames.DataFrame;types = Dict("setnowithdash" => String))

#keep only one offer for each shop!
    sort!(data, [:setnowithdash, :strStorename, :price]);
    unique!(data, [:setnowithdash, :strStorename]);

#subset data for development purposes
    setnolist = sort(unique(data.setnowithdash)[1:end])
    filter!(x -> x.setnowithdash in setnolist, data);

#init
shoplist = sort(unique(data.strStorename))
nsets, nshops = length(setnolist), length(shoplist)
countrylist = data.strSellerCountryName
data[!,:strSellerContinent] .= map(x->countryToContinentDict[x],data.strSellerCountryName)
shop_to_continentDict = Dict(data.strStorename .=> data.strSellerContinent)
shop_to_countryDict = Dict(data.strStorename .=> data.strSellerCountryName)

#shipping costs
#note this also accounts for the fact that Europe should be generally preferable (e.g. faster delivery times)
#thus it is more than only plain shipping costs, rather a generic penalty amount
@show sort(unique(collect(values(shop_to_continentDict))))
shipping_costs_by_continent = Dict("Europe"=>25,"Africa"=>120,"Asia"=>100,"North America"=>75,"South America"=>100,"Oceania"=>100)
@assert issubset(sort(unique(collect(values(shop_to_continentDict)))),keys(shipping_costs_by_continent))
shippingcosts_vec = map(x->shipping_costs_by_continent[shop_to_continentDict[x]],shoplist)
#amend individual countries
for i=1:size(shippingcosts_vec,1)
    shopname = shoplist[i]
    if shop_to_countryDict[shopname] == "Switzerland"
        shippingcosts_vec[i] = 10 
    end
end

@show countmap(shippingcosts_vec)
#=
    DataFrame(country=sort(unique(data.strSellerCountryName)))
    CSV.write(raw"C:\temp\cty.csv",ans)
=#

#M_ij == 1 <-> we buy setnolist[i] from shoplist[j]
#M_init = zeros(Int,nsets,nshops)

#objective:
#We want to minimize Sum_ij (P * M) + shipping costs 
#shipping costs = Sum_j (shoplist_shippingcosts_di[j]) for each shop j where order at least one item (i.e. if the sum of column j of M is larger than zero)

#P -> price matrix, number of rows == nshops, number of columns == nsets
#M -> optimization variable, each entry must be 0 or 1, number of rows == nsets, number of columns == nshops
#M * P -> size is nsets X nsets
#(M * P) * one_vector is a vector of length nsets
#transpose(one_vector) * ((M * P) * one_vector) should be a float

P = create_price_matrix(setnolist, shoplist, data);

@time to_buy,Mv,smry = fit_model(data,P,setnolist,shoplist,shippingcosts_vec,nsets, nshops);

to_buy
price_wo_shipping = sum(to_buy.price) 
CSV.write(raw"c:\temp\to.csv",to_buy)
0