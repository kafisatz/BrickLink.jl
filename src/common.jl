
export bringcolumnstotheleft!
function bringcolumnstotheleft!(df::DataFrame,cols::Vector{Symbol})
    #df=deepcopy(brmsdf)
    #cols=[:data,:resultado]
    nms=propertynames(df)
    if !issubset(cols,nms)
        for c in cols
            if !in(c,nms)
                @show c
            end
        end
        error("bringcolumnstotheleft: Some columns were not found in DataFrame")
    end
    @assert issubset(cols,nms)

    have=cols
    donthave=setdiff(nms,cols)
    select!(df,vcat(have,donthave))
return nothing

end
bringcolumnstotheleft!(df::DataFrame,cols::String)=bringcolumnstotheleft!(df,vcat(cols))
bringcolumnstotheleft!(df::DataFrame,cols::Symbol)=bringcolumnstotheleft!(df,vcat(cols))
bringcolumnstotheleft!(df::DataFrame,cols::Vector{String})=bringcolumnstotheleft!(df,Symbol.(cols))

export price_and_currency
function price_and_currency(x)
    #x=dfsupply0[4,"mDisplaySalePrice"]
    #x=dfsupply0[4,"mInvSalePrice"]
    po = findfirst(r"\d", x)
    @assert !isnothing(po)
    x2 = x[po[1]:end]
    x3 = replace(x2,","=>"")
    price = parse(Float64,x3)
    curr = strip(x[1:po[1]-1])

    return curr,price 
end


export parse_data
function parse_data(j::AbstractDict,itemid,setno_to_name,variables_of_interest,item_to_setno,jsvec_index_to_itemid;to="CHF")
    #j=jsvec[i]
    dfsupply0 = DataFrame(j.list)
    select!(dfsupply0,variables_of_interest)
    dfsupply0[!,:itemid] .= itemid
    dfsupply0[!,:setnowithdash] .= item_to_setno[itemid]
    dfsupply0[!,:setno] .= map(x->x[1:end-2],dfsupply0.setnowithdash)
    #error("in the works")
    dfsupply0[!,:price] = zeros(size(dfsupply0,1))
    dfsupply0[!,:price_currency] .= to
    dfsupply0[!,:name] .= map(x->setno_to_name[x],dfsupply0.setnowithdash)

    for i=1:size(dfsupply0,1)
        curr,p = price_and_currency(dfsupply0.mDisplaySalePrice[i])
        curr_to = curr * to
        if !haskey(EXCHANGE_RATES_DICT_GLOBAL,curr_to)
            fxr = fxrate(curr,to=to)
            EXCHANGE_RATES_DICT_GLOBAL[curr_to] = fxr
        end
        fxr = EXCHANGE_RATES_DICT_GLOBAL[curr_to]
        dfsupply0.price[i] = p * fxr 
    end

    bringcolumnstotheleft!(dfsupply0,[:setnowithdash,:name,:price,:price_currency,:codeComplete,:itemid,:strStorename, :mMinBuy, :strSellerCountryName])

    return dfsupply0
end
   
