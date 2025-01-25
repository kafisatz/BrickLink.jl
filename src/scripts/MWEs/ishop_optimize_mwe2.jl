using BrickLink
using JuMP;import CSV;import DataFrames;import HiGHS

@info("run ishop_fetch_data.jl to generate the data.")
data = CSV.read(raw"c:\temp\dfsupply.csv",DataFrames.DataFrame;types = Dict("setnowithdash" => String))
sort!(data, [:setnowithdash, :strStorename, :price])
unique!(data, [:setnowithdash, :strStorename])

#subset
setnolist = sort(unique(data.setnowithdash)[1:end])
filter!(x -> x.setnowithdash in setnolist, data);
shoplist = sort(unique(data.strStorename))
nsets, nshops = length(setnolist), length(shoplist)
shippingcosts_vec = fill(25.0, nshops)


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