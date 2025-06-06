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
    res = HTTP.get("$(endpoint)?$query_str"; headers = Dict{String,String}("Content-Type" => "application/x-www-form-urlencoded","Authorization" => oauth_header_val,"Accept" => "*/*"),require_ssl_verification=false)
    resdesc = JSON3.read(IOBuffer(res.body))

    if resdesc.meta.code != 200
        @warn("you likley need to add your IP here")
        println("https://www.bricklink.com/v2/api/register_consumer.page")
        @warn("Also you will need to update the auth.json file")
        @show resdesc.meta.code
        @show resdesc.meta.description
        @show resdesc.meta.message
    end

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
    resprice = HTTP.get("$(endpoint)?$query_str"; headers = Dict{String,String}("Content-Type" => "application/x-www-form-urlencoded","Authorization" => oauth_header_val,"Accept" => "*/*"),require_ssl_verification=false)

    js = JSON3.read(IOBuffer(resprice.body))
    js.data
    js.data.item.no
    js.data.new_or_used
    js.data.currency_code
    js.data.price_detail

    #extract prices
    prices = js.data.price_detail
    pricelist = Float64[]
    #i=1
    #map(x->x.shipping_available,prices)
    #prices[i]
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

    dfout.name .= fix_json_parsing.(dfout.name)

    return dfout
end

export get_prices_without_folds
function get_prices_without_folds(credentials,di::Dict,numbers::Vector)
    #request prices from BrickLink API
    dfres = DataFrames.DataFrame()
    @showprogress for setno in numbers #sets.set_no
        #@show setno
        #nostring = string(setno) * "-1"
        nostring = string(setno) 
        thisdi = deepcopy(di)
        thisdi["no"] = nostring
        try
            df = get_prices(credentials,thisdi)
            println("Querying prices for $nostring ...")
            append!(dfres,df,cols=:union)
        catch e 
            println("Error querying prices for $nostring")
            @show e
        end
    end

    return dfres
end

export get_prices
function get_prices(credentials,di::Dict,numbers::Vector)
    #request prices from BrickLink API
    get_p_fn(s) = get_prices_folds_inner(s,di,credentials)

    #testing 
    unused_df = get_p_fn(numbers[1])

    dfres = Folds.mapreduce(get_p_fn,(k,l)->append!(l,k,cols=:union), numbers,init= DataFrames.DataFrame())
    #reduce(append!, Tables.rowtable.(dts))

    #=
        numbers = map(x->string(x)*"-1",sets.set_no)[1:5]
        @time dtest = get_prices_folds(credentials,di,numbers)
        @time dtest = get_prices(credentials,di,numbers)
    =#
    return dfres 
end

export get_prices_folds_inner
function get_prices_folds_inner(setno::String,di,credentials)    
        #@show setno
        #nostring = string(setno) * "-1"
        nostring = string(setno) 
        thisdi = deepcopy(di)
        thisdi["no"] = nostring
        try
            df = get_prices(credentials,thisdi)
            return df
            #println("Querying prices for $nostring ...")
            #append!(dfres,df,cols=:union)
        catch e 
            println("Error querying prices for $nostring")
            @show e
            return DataFrame()
        end
    end

#Folds.mapreduce(f, op, collections...; [init] [executor_options...])
#=
@time df_new = get_prices(credentials,di_new,map(x->string(x)*"-1",sets.set_no))
=#