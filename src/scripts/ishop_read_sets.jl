using Revise; using BrickLink;import CSV; using DataFrames; using JSON3; using HTTP; using OAuth

#list of sets
pt = pathof(BrickLink)
fi = normpath(joinpath(pt,"..","sets_ishop.txt"))
sets = CSV.read(fi,DataFrames.DataFrame,header=false)
DataFrames.rename!(sets,Dict(1=>"set_no"));
unique!(sets);sort!(sets,:set_no)
#CSV.write(fi,sets,header=false)

itemids = get_item_id.(map(x->x*"-1",string.(sets.set_no)))

#get prices and stores: 
#https://www.bricklink.com/ajax/clone/catalogifs.ajax?itemid=52663&ss=CH&rpp=500&iconly=0
#https://www.bricklink.com/ajax/clone/catalogifs.ajax?itemid=112755&ss=CH&rpp=500&iconly=0

jsvec = get_prices_and_stores.(itemids)

#write to disk for convenience
for i=1:size(jsvec,1)
    jwrite(jsvec[i],raw"c:\temp\\" * "$(i)" * ".json")
end




##################################################################################################
#get additional information for each set
##################################################################################################
setno = 75098
setno = sets.set_no[1]
setnostring = string(setno) * "-1"
di = Dict("type"=>"SET","no"=>setnostring,"new_or_used"=>"U","currency_code"=>"CHF") #U for used, N for new
di_new = deepcopy(di)
di_new["new_or_used"] = "N"

@warn("if this fails make sure that your ip is added here: \nhttps://www.bricklink.com/v2/api/register_consumer.page")
@warn("then UPDATE auth.json")
dftest = get_prices(credentials,di)
dftest = get_prices(credentials,di_new)

#used - 262 seconds for 764 entries (non parallel)
@time df_used = get_prices(credentials,di,map(x->string(x)*"-1",sets.set_no))

df_info = select(df_used,["item","type","name","year_released","imgurl"])
df_info[!,:set_no] .= map(x->x[1:end-2],df_info.item)
##################################################################################################
##################################################################################################



##################################################################################################
#merge data 
##################################################################################################


@assert length(jsvec) == length(itemids)
@assert length(sets.set_no) == length(itemids)
@assert length(sets.set_no) == size(df_info,1)
sort!(df_info,:set_no)
sort!(sets,:set_no)

@assert isequal(df_info.set_no,sets.set_no)

df_info

dfsupply = DataFrame() 
for i=1:size(jsvec,1)
    dfsupply0 = DataFrame(jsvec[i].list)
    dfsupply0[!,:setno] .= sets.set_no[i]
end

for j=1:size(jsvec[i].list,1)
    nms = keys(jsvec[i].list)
    DataFrame(jsvec[i].list)
    @show nms
    @show length(nms)
end
