using JuMP
import CSV
import DataFrames
import HiGHS

begin
        data = CSV.read(
            download(
                raw"https://gist.githubusercontent.com/kafisatz/12ccf544a3924816be378cb785e0b04b/raw/c2baed05921e8f0e84ed0ccbdbdfb531ac7d90ab/dfsupply.csv",
            ),
            DataFrames.DataFrame;
            types = Dict("setnowithdash" => String),
        )
        sort!(data, [:setnowithdash, :strStorename, :price])
        unique!(data, [:setnowithdash, :strStorename])
        setnolist = sort(unique(data.setnowithdash)[2:7])
        filter!(x -> x.setnowithdash in setnolist, data)
        model = Model(HiGHS.Optimizer)
        set_silent(model)
        data.x_buy = @variable(model, x_buy[1:size(data, 1)], Bin)
        for df in DataFrames.groupby(data, "setnowithdash")
            @constraint(model, sum(df.x_buy) == 1)
        end
        fixed_shipping = zero(AffExpr)
        for df in DataFrames.groupby(data, "strStorename")
            x_fixed_cost = @variable(model, binary = true)
            @constraint(model, sum(df.x_buy) <= size(df, 1) * x_fixed_cost)
            add_to_expression!(fixed_shipping, 25.0 * x_fixed_cost)
        end
        @objective(model, Min, data.price' * data.x_buy + fixed_shipping)
        optimize!(model)
        @assert is_solved_and_feasible(model)
        data.x_decision = round.(Bool, value.(data.x_buy))
        filter(row -> row.x_decision, data)
    end
