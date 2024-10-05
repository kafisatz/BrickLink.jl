httpmethod = "GET"

baseurl = "https://api.bricklink.com/api/store/v1"
endpoint = string(baseurl,"/items/",di["type"],"/",di["no"],"/subsets")
#"https://api.bricklink.com/api/store/v1/items/SET/10030-1"

options = Dict{String,String}(""=>"")
query_str = HTTP.escapeuri(options)
oauth_header_val = OAuth.oauth_header(httpmethod, endpoint, options, credentials["ConsumerKey"], credentials["ConsumerSecret"], credentials["TokenValue"], credentials["TokenSecret"])

#Make request
#item details
res = HTTP.get("$(endpoint)?$query_str"; headers = Dict{String,String}("Content-Type" => "application/x-www-form-urlencoded","Authorization" => oauth_header_val,"Accept" => "*/*"))
resdesc = JSON3.read(IOBuffer(res.body))
resdesc.data
