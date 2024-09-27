export get_prices
function get_prices(credentials,di::Dict)

httpmethod = "GET"

baseurl = "https://api.bricklink.com/api/store/v1"
endpoint = string(baseurl,"/items/",di["type"],"/",di["no"])
#"https://api.bricklink.com/api/store/v1/items/SET/10030-1"

options = Dict{String,String}(""=>"")
query_str = HTTP.escapeuri(options)
oauth_header_val = OAuth.oauth_header(httpmethod, endpoint, options, credentials["ConsumerKey"], credentials["ConsumerSecret"], credentials["TokenValue"], credentials["TokenSecret"])

#Make request
#item details
res = HTTP.get("$(endpoint)?$query_str"; headers = Dict{String,String}("Content-Type" => "application/x-www-form-urlencoded","Authorization" => oauth_header_val,"Accept" => "*/*"))
resdesc = JSON3.read(IOBuffer(res.body))
resdesc.data.name
resdesc.data.year_released
imgurl = raw"https://" * resdesc.data.image_url[3:end]

@assert res.status == 200

#item prices
#options = Dict{String,String}("new_or_used"=>di["new_or_used"])
#options = Dict{String,String}("currency_code"=>di["currency_code"])
options = Dict{String,String}("currency_code"=>di["currency_code"],"new_or_used"=>di["new_or_used"])
#@show di["new_or_used"]
query_str = HTTP.escapeuri(options)
endpoint = string(baseurl,"/items/",di["type"],"/",di["no"],"/price")
oauth_header_val = OAuth.oauth_header(httpmethod, endpoint, options, credentials["ConsumerKey"], credentials["ConsumerSecret"], credentials["TokenValue"], credentials["TokenSecret"])
resprice = HTTP.get("$(endpoint)?$query_str"; headers = Dict{String,String}("Content-Type" => "application/x-www-form-urlencoded","Authorization" => oauth_header_val,"Accept" => "*/*"))

js = JSON3.read(IOBuffer(resprice.body))
js.data
js.data.item.no
js.data.new_or_used
js.data.currency_code
js.data.price_detail

#extract prices
prices = js.data.price_detail
pricelist = Float64[]
for i=1:length(prices)
    if prices[i].shipping_available == true
        prices[i].unit_price
        push!(pricelist,parse(Float64,prices[i].unit_price))
    end    
end
sort!(pricelist)

js.data
df = DataFrames.DataFrame(p=pricelist)
df2 = permutedims(df)
name = resdesc.data.name
year_released = resdesc.data.year_released
imgurl = raw"https://" * resdesc.data.image_url[3:end]
df3 = DataFrames.DataFrame(item=js.data.item.no,type=js.data.item.type,name=name,year_released = year_released,new_or_used=js.data.new_or_used,currency=js.data.currency_code,imgurl=imgurl)
dfout = hcat(df3,df2)

return dfout 
end

export get_prices
function get_prices(credentials,di::Dict,sets::DataFrames.DataFrame)
    #request prices from BrickLink API
    dfres = DataFrames.DataFrame()
    for setno in sets.set_no
        #@show setno
        setnostring = string(setno) * "-1"
        thisdi = deepcopy(di)
        thisdi["no"] = setnostring
        try
            df = get_prices(credentials,thisdi)
            println("Querying prices for set $setnostring ...")
            append!(dfres,df,cols=:union)
        catch e 
            println("Error querying prices for set $setnostring")
            @show e
        end
    end

    return dfres
end

