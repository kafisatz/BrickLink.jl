using Revise; using BrickLink;import CSV; using DataFrames; using JSON3; using HTTP; using OAuth

#list of sets
pt = pathof(BrickLink)
fi = normpath(joinpath(pt,"..","set_list.txt"))
sets = CSV.read(fi,DataFrames.DataFrame,header=false)
DataFrames.rename!(sets,Dict(1=>"set_no"));
unique!(sets);sort!(sets,:set_no)
#CSV.write(fi,sets,header=false)
 
#credentials
fldr = ENV["USERPROFILE"]
fi = joinpath(fldr,"auth.json")
@assert isfile(fi)
credentials = JSON3.read(fi);

#test
setno = 75098
setno = sets.set_no[1]
setnostring = string(setno) * "-1"
di = Dict("type"=>"SET","no"=>setnostring,"new_or_used"=>"U","currency_code"=>"CHF") #U for used, N for new
di_new = deepcopy(di)
di_new["new_or_used"] = "N"

@warn("if this fails make sure that your ip is added here: \nhttps://www.bricklink.com/v2/api/register_consumer.page")
@warn("then UPDATE auth.json")
dftest = get_prices(credentials,di)
dftest = get_prices(credentials,di_new)

#used - ca. 20 seconds for 950 items (Folds) - without Folds -> 262 seconds for 764 entries (non parallel)
@time df_used = get_prices(credentials,di,map(x->string(x)*"-1",sets.set_no))

#new prices - 21 seconds with Folds (764 items)
@time df_new = get_prices(credentials,di_new,map(x->string(x)*"-1",sets.set_no))

#download images
imgfldr = raw"C:\Users\bernhard.koenig\OneDrive - K\Dateien\Lego\starwars_bricklink_images"
@assert isdir(imgfldr)
download_images(df_used,imgfldr)

#discard columns after price 200 (too many columns for mySQL table #1118 - Row size too large (> 8126))

#keep first 200 columns only
df_used = df_used[:, 1:min(200, size(df_used, 2))]
df_new = df_new[:, 1:min(200, size(df_new, 2))]

CSV.write(raw"C:\temp\prices_used.csv",df_used)
CSV.write(raw"C:\temp\prices_new.csv",df_new)
#mf = get_minifigs("75173-1",credentials)

using MySQL
mysqlpassword = ENV["mysqlpassword.55ip"]
mysqlusername = "root"
mysqlhost = "10.14.15.55"

conn = DBInterface.connect(MySQL.Connection,mysqlhost, mysqlusername, mysqlpassword, db="brick")
#drop table from DB 
DBInterface.execute(conn, "DROP TABLE IF EXISTS prices_used;")
DBInterface.execute(conn, "DROP TABLE IF EXISTS prices_new;")
MySQL.load(df_used, conn, "prices_used")
MySQL.load(df_new, conn, "prices_new")