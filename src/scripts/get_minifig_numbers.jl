using Dates; using Revise; using BrickLink;import CSV; using DataFrames; using JSON3; using HTTP; using OAuth;using Folds
#minifigure / minifig script
#credentials
fldr = ENV["USERPROFILE"]; fi = joinpath(fldr,"auth.json"); @assert isfile(fi)
credentials = JSON3.read(fi);

#test if current IP has access
#https://www.bricklink.com/v2/api/register_consumer.page
mf = get_minifigs("75125-1",credentials); @assert size(mf,1) >0
mf = get_minifigs("7181-1",credentials); @assert size(mf,1) == 0
mf = get_minifigs("75397-1",credentials); @assert size(mf,1) >5

#CSV.write(joinpath(ENV["USERPROFILE"],"OneDrive - K","Dateien","Lego","BrickLink","minifigs.csv"),mf)

#get them DIRECTLY
list_all = sort(unique(convert(Vector{String},CSV.read(raw"q:\minifigdb\unique_minifig_codes20250703-233643.csv",DataFrame).minifig_code)))
listsw0 = CSV.read(raw"q:\minifigdb\minifigs_sw.csv", DataFrame)
listsw = convert(Vector{String},(listsw0.minifig))

error("bricklink is blocking this..... for 10k minifigs...")
#15 s #bricklink is blocking this.....
@time minifigdf = get_minifig_list(listsw,credentials)
CSV.write(raw"Q:\minifigdb\MinifigDB.csv",minifigdf)

#15 s
@time minifigdfall = get_minifig_list(list_all[1:100],credentials)
timestamp = Dates.format(Dates.now(),"yyyymmdd-HHMMSS")
CSV.write(joinpath(raw"Q:\minifigdb",string("MinifigDBall",timestamp,".csv")),minifigdfall)

#download images 
function dn(minifigdf)
    outdir =raw"Q:\reference_images\bricklink"
    @assert isdir(outdir)
    Folds.map(x->download(string("https:",x.image_url),joinpath(outdir,string(x.minifig,splitext(rw.image_url)[2]))),eachrow(minifigdf))
    return nothing 
end

#takes 16 seconds
#@time dn(minifigdf[1:end,:])

###############################################################
#old approach with 'set' reference 
###############################################################
if false 
    #read set list (all LSW)
    df = CSV.read(joinpath(ENV["USERPROFILE"],"OneDrive - K","Dateien","Lego","brickset","sets.csv"),DataFrame)
    setnos = convert(Vector{String},map(x->x*"-1",df.number))

    #setnos = map(x->string(x)*"-1",sets.set_no)

    setnos_SHORT = setnos[1:13]
    mfs = get_minifigs(setnos_SHORT,credentials)

    #20 seconds for 150 sets ~ 450 minifigs
    #242 seconds for 1381 sets
    @time mf = get_minifigs(setnos,credentials)
end 
