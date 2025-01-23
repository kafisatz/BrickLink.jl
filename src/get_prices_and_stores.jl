export get_prices_and_stores
function get_prices_and_stores(itemid::String)
    #itemid="112755"
    country = "CH"
    #https://www.bricklink.com/ajax/clone/catalogifs.ajax?itemid=52663&ss=CH&rpp=500&iconly=0
    url = "https://www.bricklink.com/ajax/clone/catalogifs.ajax?itemid=$(itemid)&ss=$(country)&rpp=500&iconly=0"
    rs = HTTP.get(url,require_ssl_verification=false)
    
    js = JSON3.read(rs.body)
    #= 
        js.list
        js.list[1]
    =#
    
    return js
end