export create_price_matrix
function create_price_matrix(setnolist,shoplist,data;infinite_price=9e20)
    #infinite_price to indicate that the shop has no offering for this set 
    #as we minimize the overall price, we set this to a large value ~ infinite
    #Float Matrix
    nsets = length(setnolist)
    nshops = length(shoplist)

    #checks
    for shop in shoplist
        dftmp = filter(x->x.strStorename==shop,data)
        @assert size(dftmp,1) > 0
    end
    for setno in setnolist
        dftmp = filter(x->x.setnowithdash==setno,data)
        @assert size(dftmp,1) > 0
    end

    pricedict = Dict()
    for i=1:size(data,1)
        #for i=1:11
        setno = data.setnowithdash[i]
        shop = data.strStorename[i]
        price = data.price[i]
        pricedict[(setno,shop)] = price
        @show i,length(pricedict),i-length(pricedict)
    end

    p = zeros(nshops,nsets)
    for i=1:nshops 
        for j=1:nsets 
            setno = setnolist[j]
            shop = shoplist[i]
            if haskey(pricedict,(setno,shop))
                p[i,j] = pricedict[(setno,shop)]
            else
                p[i,j] = infinite_price
            end            
        end
    end

    #consistency checks
    @show sum(p .< infinite_price) , size(data,1), size(data,1) - sum(p .< infinite_price) 
    @assert sum(p .< infinite_price) == size(data,1)

    return p 
end
