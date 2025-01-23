#sview-source:https://www.bricklink.com/v2/catalog/catalogitem.page?S=75367-1#T=I

export get_item_id
function get_item_id(setno)
    #setno="75290-1"
    url = "https://www.bricklink.com/v2/catalog/catalogitem.page?S=$(setno)#T=I"
    rs = HTTP.get(url,require_ssl_verification=false)
    
    bdy = String(rs.body);
    @assert length(bdy) > 0 

    findstr = "itemid="
    bdy = lowercase.(bdy)

    fnd = findall(findstr,bdy)
    @assert !isnothing(bdy)
    @assert size(fnd,1) > 0 

    showlen = 30
    cands = String[]
    for i=1:size(fnd,1)
        #show strings 
        #@show bdy[fnd[i][end]+1:fnd[i][1] + showlen]
        push!(cands,bdy[fnd[i][end]+1:fnd[i][1] + showlen])
    end

    for i=1:size(cands,1) 
        cands[i] = replace(cands[i],"\""=>"")
        cands[i] = replace(cands[i]," "=>"")
        cands[i] = split(cands[i], "&")[1]
    end

    #determine if string contains anything other than digits
    #keep entries with digits only
    filter!(x->isnothing(match(r"\D", x)) ,cands)
    @assert size(unique(cands),1) == 1
    
    return cands[1] 
end