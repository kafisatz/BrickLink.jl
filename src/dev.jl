httpmethod = "GET"

di["no"]="7181-1"
di["no"]="75290-1" #mos eisley
di["no"]="75173-1" #landspeeder
baseurl = "https://api.bricklink.com/api/store/v1"
endpoint = string(baseurl,"/items/",di["type"],"/",di["no"],"/subsets") #,"?break_minifigs=true")
#endpoint = string(baseurl,"/items/",di["type"],"/",di["no"]) #
#"https://api.bricklink.com/api/store/v1/items/SET/10030-1"
endpoint

options = Dict{String,String}("break_minifigs"=>"false","break_subsets"=>"false")
query_str = HTTP.escapeuri(options)
oauth_header_val = OAuth.oauth_header(httpmethod, endpoint, options, credentials["ConsumerKey"], credentials["ConsumerSecret"], credentials["TokenValue"], credentials["TokenSecret"])

#Make request
#item details
res = HTTP.get("$(endpoint)?$query_str"; headers = Dict{String,String}("Content-Type" => "application/x-www-form-urlencoded","Authorization" => oauth_header_val,"Accept" => "*/*"))
resdesc = JSON3.read(IOBuffer(res.body))
resdesc.data
#write to file 
fi = raw"C:\temp\resdesc.json"
open(fi,"w") do io
    JSON3.print(io,resdesc)
end
resdesc.data



setno = "75173-1"
mf = get_minifigs("75173-1",credentials)