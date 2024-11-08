    #
export get_minifigs 
function get_minifigs(setno::String,credentials;append_setno=true)
    
    type="SET"
    @assert occursin("-",setno) "You must provide the set number in the format 75173-1"

    baseurl = "https://api.bricklink.com/api/store/v1"
    endpoint = string(baseurl,"/items/",type,"/",setno,"/subsets")
    #"https://api.bricklink.com/api/store/v1/items/SET/10030-1"
    
    httpmethod = "GET"
    options = Dict{String,String}("break_minifigs"=>"false","break_subsets"=>"false")
    query_str = HTTP.escapeuri(options)
    oauth_header_val = OAuth.oauth_header(httpmethod, endpoint, options, credentials["ConsumerKey"], credentials["ConsumerSecret"], credentials["TokenValue"], credentials["TokenSecret"])
    
    #Make request
    res = HTTP.get("$(endpoint)?$query_str"; headers = Dict{String,String}("Content-Type" => "application/x-www-form-urlencoded","Authorization" => oauth_header_val,"Accept" => "*/*"),require_ssl_verification=false)
    resdesc = JSON3.read(IOBuffer(res.body))
    resdesc.data
    size(resdesc.data)
    entry = resdesc.data[1]
    #create empty json object 
    minifigs = DataFrames.DataFrame(minifig=String[],name=String[],category_id=Int[])
    for i=1:size(resdesc.data,1)
        for j=1:size(resdesc.data[i].entries,1)
            if "MINIFIG" == resdesc.data[i].entries[j].item.type
                df00 = DataFrames.DataFrame(minifig=resdesc.data[i].entries[j].item.no,name=resdesc.data[i].entries[j].item.name,category_id=resdesc.data[i].entries[j].item.category_id)
                append!(minifigs,df00)
            end
        end
    end

    #fix special characters
    minifigs.name .= fix_json_parsing.(minifigs.name)
        
    if append_setno
        minifigs[!,:setno] .= setno
    end

    return minifigs
end

function get_minifigs(setnos::Vector,credentials;append_setno=true)
    minifigs = DataFrames.DataFrame(minifig=String[],setno=String[],name=String[],category_id=Int[])
    @showprogress for i=1:length(setnos)
        try
            mf = get_minifigs(setnos[i],credentials,append_setno=append_setno)
            append!(minifigs,mf)
        catch e 
            @warn("Error for set: $(setnos[i])")
            @show e
        end
    end
    return minifigs
end

export fix_json_parsing
function fix_json_parsing(str)
    #str = """an Serving Tray, Flat Silver Head &#40;75397&#41"""
    #&#40;75397&#41;

    di = Dict("&#40;"=>"(","&#41;"=>")","&#39;"=>"'")
    for (k,v) in di
        str = replace(str,k => v)
    end
    
    return str
end


    