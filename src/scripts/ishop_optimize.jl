#using Revise; using BrickLink;import CSV; using DataFrames; using JSON3; using HTTP; using OAuth; using Dates ; using StatsBase
using CSV; using DataFrames
##################################################################################################
#optimize shopping
##################################################################################################
using JuMP #for optimization
#using HiGHS
#using Ipopt
using LinearAlgebra
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

nsets = length(setnolist)
nshops = length(shoplist)
#M_ij == 1 <-> we buy setnolist[i] from shoplist[j]
#M_init = zeros(Int,nsets,nshops)

#set shipping costs (constant for now)
shipping_cost_fixed_value = 25.0
shoplist_shippingcosts_di = Dict(shoplist .=> shipping_cost_fixed_value)
shippingcosts_vec = ones(nshops) .* shipping_cost_fixed_value

infinite_price = 9e20 #large number (if item is not available in a certain shop)

P = create_price_matrix(setnolist,shoplist,data);
one_vector = ones(Int,nsets)
#objective:
#We want to minimize Sum_ij (P * M) + shipping costs 
#shipping costs = Sum_j (shoplist_shippingcosts_di[j]) for each shop j where order at least one item (i.e. if the sum of column j of M is larger than zero)

#P -> price matrix, number of rows == nshops, number of columns == nsets
#M -> optimization variable, each entry must be 0 or 1, number of rows == nsets, number of columns == nshops
#M * P -> size is nsets X nsets
#(M * P) * one_vector is a vector of length nsets
#transpose(one_vector) * ((M * P) * one_vector) should be a float
shipping_costs = 0.0

#testing LinAlg
Mtest = rand(nsets,nshops);
transpose(one_vector) * ((Mtest * P) * one_vector) + shipping_costs

oneM = ones(Int,size(P))
fill!(Mtest,0.0)
Mtest[1,1] = 1; Mtest[2,2] = 1; Mtest[3,2] = 1; Mtest[4,2] = 1;  Mtest[5,3] = 1; Mtest[6,4] = 1;
oneM * Mtest
shipping_costs = dot(shippingcosts_vec , (transpose(ones(nshops)) * (oneM * Mtest) .> 0))
shipping_costs = dot(shippingcosts_vec , map(x->min(1,x),(transpose(ones(nshops)) * (oneM * Mtest))[:] ))
objective_costs = transpose(one_vector) * ((Mtest * P) * one_vector) + shipping_costs

sum(Mtest,dims=1)
transpose(one_vector) * ((Mtest * P) * one_vector) + shipping_costs

#using JuMP;using Alpine;using Ipopt;using HiGHS
#using HiGHS; model = Model(HiGHS.Optimizer)
#using Ipopt; model = Model(Ipopt.Optimizer)
using Alpine;using Ipopt;using HiGHS;ipopt = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0) ; highs = optimizer_with_attributes(HiGHS.Optimizer, "output_flag" => false); model = Model(optimizer_with_attributes(Alpine.Optimizer,"nlp_solver" => ipopt,"mip_solver" => highs,),)
#using MadNLP; model = Model(()->MadNLP.Optimizer(print_level=MadNLP.INFO, max_iter=100))
#using Juniper;using Ipopt; ipopt = optimizer_with_attributes(Ipopt.Optimizer, "print_level"=>0); optimizer = optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>ipopt); model = Model(optimizer)

#M_ij == true <-> we buy setnolist[i] from shoplist[j]
@variable(model, M[i = 1:nsets, j = 1:nshops],integer = true)
#M_ij must be 0 or 1
@constraint(model, [i = 1:nsets, j = 1:nshops], 0 <= M[i,j] <= 1)

#buy each item once
for i in 1:nsets
    @constraint(model, sum(M[i,j] for j in 1:nshops) == 1)
end

#set initial values
for i=1:nsets
    for j=1:nshops
        set_start_value(M[i,j],0)
    end
end

#@objective(model,Min, transpose(one_vector) * ((M * P) * one_vector) + dot(shippingcosts_vec , map(x->min(1,x),(transpose(ones(nshops)) * (oneM * M))[:] )) ) #Matrix notation
#@objective(model,Min, sum(M[i,j] * P[j,i] for i in 1:nsets,j in 1:nshops) + dot(shippingcosts_vec , map(x->min(1,x),(transpose(ones(nshops)) * (oneM * M))[:] )) )
@objective(model,Min, sum(M[i,j] * P[j,i] for i in 1:nsets,j in 1:nshops) + sum(ifelse(sum(M,dims=1)[i] > 0 , shippingcosts_vec[i] , 0) for i = 1:nshops) )

#https://discourse.julialang.org/t/jump-defining-objective-function-uses-matrix-multiplication/50169/3
#@objective(m, Min, 0.5 * ((U’ * (I’ * I)) * U) + transpose(-1 * (I’ * z)) * U)

print(model)

@time optimize!(model)

primal_status(model)
dual_status(model)
objective_value(model)
is_solved_and_feasible(model)