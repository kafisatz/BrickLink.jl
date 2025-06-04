fi = normpath(joinpath(pathof(BrickLink),"..","..","..","BrickSet.jl","src","set_have.txt"))
@assert isfile(fi)

sets = CSV.read(fi,DataFrames.DataFrame,header=false)
DataFrames.rename!(sets,Dict(1=>"set_no")); sets.set_no .= convert(Vector{String},strip.(string.(sets.set_no)))
unique!(sets); sort!(sets)
#CSV.write(fi,sets,header=false)

in("75338",sets.set_no)

using MySQL
mysqlpassword = ENV["mysqlpassword.55ip"]
mysqlusername = "root"
mysqlhost = "10.14.15.55"

conn = DBInterface.connect(MySQL.Connection,mysqlhost, mysqlusername, mysqlpassword, db="brick")
used_prices = DBInterface.execute(conn,"select * from prices_used") |> DataFrame

have_list = Set(map(x->x*"-1",sets.set_no))
used_prices_dont_have = filter(x->!(x.item in have_list),used_prices)

in("75338-1",used_prices_dont_have.item)

#only consider sets which have at least 4 offers
filter!(x->!ismissing(x.x4),used_prices_dont_have)
sort!(used_prices_dont_have,:x1,rev=true)

#add information from Brickset 

brickset_df = DBInterface.execute(conn,"select * from sets") |> DataFrame

brickset_df[!,:item] = map(x->x*"-1",brickset_df.number)

# left join brickset_df information to the dataframe used_prices_dont_have
used_prices_dont_have2 = leftjoin(used_prices_dont_have, brickset_df, on=:item, makeunique=true)

used_prices_dont_have2[!,:price_per_piece_x4] .= map(x->x.x4/x.pieces,eachrow(used_prices_dont_have2))

# move price columns x1, x2, x3, ... to the far right
price_cols = filter(col -> occursin(r"^x\d+$", String(col)), names(used_prices_dont_have2))
other_cols = setdiff(names(used_prices_dont_have2), price_cols)
used_prices_dont_have2 = used_prices_dont_have2[:, vcat(other_cols, price_cols)]

CSV.write(raw"C:\temp\sets_dont_have_used_prices.csv",used_prices_dont_have2)