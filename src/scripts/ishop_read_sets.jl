using Revise; using BrickLink;import CSV; using DataFrames; using JSON3; using HTTP; using OAuth; using Dates ; using StatsBase

#read list of sets
pt = pathof(BrickLink)
fi = normpath(joinpath(pt,"..","sets_ishop.txt"))
sets = CSV.read(fi,DataFrames.DataFrame,header=false)
DataFrames.rename!(sets,Dict(1=>"setno"));
unique!(sets);sort!(sets,:setno)
#CSV.write(fi,sets,header=false)

sets[!,:setnowithdash] .= map(x->x*"-1",string.(sets.setno))
itemids = get_item_id.(sets.setnowithdash)
sets[!,:itemid] .= itemids

#get prices and stores: 
#https://www.bricklink.com/ajax/clone/catalogifs.ajax?itemid=52663&ss=CH&rpp=500&iconly=0
#https://www.bricklink.com/ajax/clone/catalogifs.ajax?itemid=112755&ss=CH&rpp=500&iconly=0
jsvec = get_prices_and_stores.(itemids)
jsvec_index_to_itemid = Dict(1:size(jsvec,1) .=> itemids)
#write to disk for convenience
for i=1:size(jsvec,1)
    jwrite(jsvec[i],raw"c:\temp\\" * "$(i)" * ".json")
end

##################################################################################################
#get additional information for each set
##################################################################################################
setno = 75098
setnostring = sets.setnowithdash[1]
di = Dict("type"=>"SET","no"=>setnostring,"new_or_used"=>"U","currency_code"=>"CHF") #U for used, N for new
di_new = deepcopy(di)
di_new["new_or_used"] = "N"

#credentials
fldr = ENV["USERPROFILE"]
fi = joinpath(fldr,"auth.json")
@assert isfile(fi)
credentials = JSON3.read(fi);

@warn("if this fails make sure that your ip is added here: \nhttps://www.bricklink.com/v2/api/register_consumer.page")
@warn("then UPDATE auth.json")
dftest = get_prices(credentials,di)
dftest = get_prices(credentials,di_new)

#used - 262 seconds for 764 entries (non parallel)
@time df_used = get_prices(credentials,di,sets.setnowithdash)

df_info = select(df_used,["item","type","name","year_released","imgurl"])
rename!(df_info,"item"=>"setnowithdash")
df_info[!,:setno] .= map(x->x[1:end-2],df_info.setnowithdash)
bringcolumnstotheleft!(df_info,[:setno,:setnowithdash])
##################################################################################################


##################################################################################################
#merge data 
##################################################################################################
sort!(df_info,:setnowithdash)
sort!(sets,:setnowithdash)
item_to_setno = Dict(sets.itemid .=> sets.setnowithdash)
setno_to_item = Dict( sets.setnowithdash .=> sets.itemid)
setno_to_name = Dict( df_info.setnowithdash .=> df_info.name)
df_info[!,:itemid] .= map(x->setno_to_item[x],df_info.setnowithdash)

#checks
@assert length(setno_to_item) == length(item_to_setno)
@assert length(setno_to_name) == length(item_to_setno)
@assert all(map(i->setno_to_item[collect(values(item_to_setno))[i]] == collect(keys(item_to_setno))[i],1:length(item_to_setno)))

@assert length(jsvec) == length(itemids)
@assert length(sets.setnowithdash) == length(itemids)
@assert length(sets.setnowithdash) == size(df_info,1)
@assert isempty(setdiff(df_info.setnowithdash,sets.setnowithdash))
@assert isempty(setdiff(sets.setnowithdash,df_info.setnowithdash))
@assert isequal(df_info.setnowithdash,sets.setnowithdash)

variables_of_interest = ["idInv", "strDesc", "codeNew", "codeComplete", "strInvImgUrl", "idInvImg", "n4Qty", "hasExtendedDescription", "instantCheckout", "mDisplaySalePrice", "mInvSalePrice", "nSalePct", "strStorename", "idCurrencyStore", "mMinBuy", "strSellerUsername", "n4SellerFeedbackScore", "strSellerCountryName"]
#names(dfsupply0)
#CSV.write(raw"c:\temp\ab.csv",dfsupply0)

dfsupply = DataFrame()
supply_dict = Dict{String,DataFrame}()
for i=1:size(jsvec,1)
    dfsupply0 = parse_data(jsvec[i],jsvec_index_to_itemid[i],setno_to_name,variables_of_interest,item_to_setno,jsvec_index_to_itemid);
    setnowithdash = item_to_setno[jsvec_index_to_itemid[i]]
    supply_dict[setnowithdash] = deepcopy(dfsupply0)
    append!(dfsupply,dfsupply0);
end

#discard incomplete sets 
#I think: B == incomplete, C = complete (used), S == sealed, X == new but no sealed, s = New but not sealed (X is the same as s ??) (maybe X is New 'without comment'?)
filter!(x->x.codeComplete != "B",dfsupply)

##################################################################################################
#optimize shopping
##################################################################################################


countmap(dfsupply.codeComplete)

