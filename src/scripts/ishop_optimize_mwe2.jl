using JuMP
import CSV
import DataFrames
import HiGHS
data = CSV.read(
    download(
        raw"https://gist.githubusercontent.com/kafisatz/12ccf544a3924816be378cb785e0b04b/raw/c2baed05921e8f0e84ed0ccbdbdfb531ac7d90ab/dfsupply.csv",
    ),
    DataFrames.DataFrame;
    types = Dict("setnowithdash" => String),
)
sort!(data, [:setnowithdash, :strStorename, :price])
unique!(data, [:setnowithdash, :strStorename])
setnolist = sort(unique(data.setnowithdash)[1:end])
filter!(x -> x.setnowithdash in setnolist, data);
shoplist = sort(unique(data.strStorename))
nsets, nshops = length(setnolist), length(shoplist)
shippingcosts_vec = fill(25.0, nshops)

function create_price_matrix(setnolist, shoplist, data)
    nsets, nshops = length(setnolist), length(shoplist)
    for shop in shoplist
        @assert size(filter(x -> x.strStorename == shop, data), 1) > 0
    end
    for setno in setnolist
        @assert size(filter(x -> x.setnowithdash == setno, data), 1) > 0
    end
    pricedict = Dict(
        (data.setnowithdash[i], data.strStorename[i]) => data.price[i]
        for i in 1:size(data,1)
    )
    p = [
        get(pricedict, (setnolist[i], shoplist[j]), Inf)
        for i in 1:nsets, j in 1:nshops
    ]
    @assert sum(p .< Inf) == size(data, 1)
    return p 
end

P = create_price_matrix(setnolist, shoplist, data);
model = Model(HiGHS.Optimizer)
@variable(
    model,
    0 <= M[i in 1:nsets, j in 1:nshops] <= ifelse(P[i, j] == Inf, 0, 1),
    Bin,
)
@variable(model, M_fixed_cost[1:nshops], Bin)
@constraint(model, [i in 1:nsets], sum(M[i, :]) == 1)
@constraint(model, [j in 1:nshops], sum(M[:, j]) <= nshops * M_fixed_cost[j])
@objective(
    model,
    Min,
    sum(M[i,j] * P[i,j] for i in 1:nsets, j in 1:nshops if P[i,j] < Inf) +
    sum(M_fixed_cost[j] * shippingcosts_vec[j] for j in 1:nshops),
)
optimize!(model)


primal_status(model)
dual_status(model)
objective_value(model)
is_solved_and_feasible(model)