using Revise; using BrickLink;import CSV; using DataFrames; using JSON3; using HTTP; using OAuth
#credentials
fldr = ENV["USERPROFILE"]; fi = joinpath(fldr,"auth.json"); @assert isfile(fi)
credentials = JSON3.read(fi);

#test if current IP has access
#https://www.bricklink.com/v2/api/register_consumer.page
mf = get_minifigs("75125-1",credentials); @assert size(mf,1) >0
mf = get_minifigs("7181-1",credentials); @assert size(mf,1) == 0
mf = get_minifigs("75397-1",credentials); @assert size(mf,1) >5

#read set list (all LSW)
df = CSV.read(joinpath(ENV["USERPROFILE"],"OneDrive - K","Dateien","Lego","brickset","sets.csv"),DataFrame)
setnos = convert(Vector{String},map(x->x*"-1",df.number))

#setnos = map(x->string(x)*"-1",sets.set_no)

setnos_SHORT = setnos[1:13]
mfs = get_minifigs(setnos_SHORT,credentials)

#20 seconds for 150 sets ~ 450 minifigs
#242 seconds for 1381 sets
@time mf = get_minifigs(setnos,credentials)

CSV.write(joinpath(ENV["USERPROFILE"],"OneDrive - K","Dateien","Lego","BrickLink","minifigs.csv"),mf)
