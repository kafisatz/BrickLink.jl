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
        #@show i,length(pricedict),i-length(pricedict)
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
    #@show sum(p .< infinite_price) , size(data,1), size(data,1) - sum(p .< infinite_price) 
    @assert sum(p .< infinite_price) == size(data,1)

    return p 
end

export fit_model
function fit_model(data,P,setnolist,shoplist,shippingcosts_vec,nsets, nshops)
        
    #M_ij == 1 <-> we buy setnolist[i] from shoplist[j]
    #M_init = zeros(Int,nsets,nshops)

    #objective:
    #We want to minimize Sum_ij (P * M) + shipping costs 
    #shipping costs = Sum_j (shoplist_shippingcosts_di[j]) for each shop j where order at least one item (i.e. if the sum of column j of M is larger than zero)

    #P -> price matrix, number of rows == nshops, number of columns == nsets
    #M -> optimization variable, each entry must be 0 or 1, number of rows == nsets, number of columns == nshops
    #M * P -> size is nsets X nsets
    #(M * P) * one_vector is a vector of length nsets
    #transpose(one_vector) * ((M * P) * one_vector) should be a float


    model = Model(HiGHS.Optimizer)
    @variable(
        model,
        0 <= M[i in 1:nsets, j in 1:nshops] <= ifelse(P[j,i] == Inf, 0, 1),
        Bin,
    )
    @variable(model, M_fixed_cost[1:nshops], Bin)
    #buy each set once
    @constraint(model, [i in 1:nsets], sum(M[i, :]) == 1)
    @constraint(model, [j in 1:nshops], sum(M[:, j]) <= nsets * M_fixed_cost[j])
    @objective(
        model,
        Min,
        sum(M[i,j] * P[j,i] for i in 1:nsets, j in 1:nshops if P[j,i] < Inf) +
        sum(M_fixed_cost[j] * shippingcosts_vec[j] for j in 1:nshops),
    )
    optimize!(model)

    @show termination_status(model)
    @show primal_status(model)
    @show objective_value(model)
    @show is_solved_and_feasible(model)

    if termination_status(model) != JuMP.MOI.OPTIMAL
        @warn("Unexpected status! termination_status")
    end
    if primal_status(model) != JuMP.MOI.FEASIBLE_POINT
        @warn("Unexpected status! primal_status")
    end
    if !is_solved_and_feasible(model)
        @warn("Unexpected status! is_solved_and_feasible")
    end

    Mv = JuMP.value.(M)
    @assert sum(Mv) == nsets

    n_items_per_shop = sum(Mv,dims=1)[:]
    shop_idx = findall(x->x>0,n_items_per_shop)
    shops_selected = shoplist[shop_idx]

    to_buy_tmp = deepcopy(data)
    filter!(x->x.strStorename in shops_selected,to_buy_tmp)

    to_buy = DataFrame();
    for shopnb in shop_idx
        shopstr = shoplist[shopnb]
        setnorows = findall(x->x>0,Mv[:,shopnb])
        
        dftmp = filter(x->x.strStorename == shopstr,to_buy_tmp)
        filter!(x->x.setnowithdash in setnolist[setnorows],dftmp)
    
        @assert size(dftmp,1) >0 
        append!(to_buy,dftmp)    
    end

    @assert size(to_buy,1) == nsets
    sum(to_buy.price)
    @assert isapprox(sum(to_buy.price) + sum(shippingcosts_vec[shop_idx])  - objective_value(model),0)

    gb = groupby(to_buy,[:strStorename,:strSellerCountryName])
    smry = combine(gb,:price => sum =>:price,:strSellerCountryName => length => :Lots)
    sort!(smry,:price,rev=true)

    return to_buy,Mv,smry
end
