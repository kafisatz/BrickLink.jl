using BrickLink;import CSV

pt = pathof(BrickLink)
fi = normpath(joinpath(pt,"..","ucs_list.txt"))
sets = CSV.read(fi,DataFrames.DataFrame,header=false)
DataFrames.rename!(sets,Dict(1=>"set_no"))