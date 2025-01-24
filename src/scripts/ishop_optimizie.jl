using Revise; using BrickLink;import CSV; using DataFrames; using JSON3; using HTTP; using OAuth; using Dates ; using StatsBase

##################################################################################################
#optimize shopping
##################################################################################################
using JuMP #for optimization
using HiGHS
@info("run ishop_fetch_data.jl to generate the data.")
data = CSV.read(raw"C:\temp\dfsupply.csv",DataFrame,types=Dict("setnowithdash"=>String));
#keep only one offer for each shop!
    sort!(data,[:setnowithdash,:strStorename,:price])
    unique!(data,[:setnowithdash,:strStorename])

setnolist = sort(unique(data.setnowithdash)[2:7])
#filter for debugging / development
filter!(x->x.setnowithdash in setnolist,data);
@show unique(data.name)

shoplist = sort(unique(data.strStorename))
#set shipping costs (constant for now)
shoplist_shippingcosts_di = Dict(shoplist .=> 25)

nsets = length(setnolist)
nshops = length(shoplist)
#M_ij == 1 <-> we buy setnolist[i] from shoplist[j]
#M_init = zeros(Int,nsets,nshops)

model = Model(HiGHS.Optimizer)
#M_ij == true <-> we buy setnolist[i] from shoplist[j]
@variable(model, M[i = 1:nsets, j = 1:nshops],integer = true)

#M_ij must be 0 or 1
@constraint(model, [i = 1:nsets, j = 1:nshops], 0 <= M[i,j] <= 1)

#buy each item once
for i in 1:nsets
    @constraint(model, sum(M[i,j] for j in 1:nshops) == 1)
end

infinite_price = 9e20 #large number (if item is not available in a certain shop)
P = create_price_matrix(setnolist,shoplist,data)
one_vector = ones(Int,nsets)
#objective:
#We want to minimize Sum_ij (P * M) + shipping costs 
#shipping costs = Sum_j (shoplist_shippingcosts_di[j]) for each shop j where order at least one item (i.e. if the sum of column j of M is larger than zero)

#P -> price matrix, number of rows == nshops, number of columns == nsets
#M -> optimization variable, each entry must be 0 or 1, number of rows == nsets, number of columns == nshops
#M * P -> size is nsets X nsets
#(M * P) * one_vector is a vector of length nsets
#transpose(one_vector) * ((M * P) * one_vector) should be a float
shipping costs = xyz #in the works
Mtest = rand(nsets,nshops); transpose(one_vector) * ((Mtest * P) * one_vector) + shipping_costs

@objective(
    model,
    Min,
    sum((data[i] - μ)^2 for i in 1:nsets) / (2 * σ^2) + 
    n / 2 * log(1 / (2 * π * σ^2)) -
    sum((data[i] - μ)^2 for i in 1:n) / (2 * σ^2)
)

#https://discourse.julialang.org/t/jump-defining-objective-function-uses-matrix-multiplication/50169/3
#@objective(m, Min, 0.5 * ((U’ * (I’ * I)) * U) + transpose(-1 * (I’ * z)) * U)

@objective(model, Min, sum(foods.cost .* foods.x));

data