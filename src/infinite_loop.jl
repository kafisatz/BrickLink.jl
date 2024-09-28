using Pkg
Pkg.activate(".")
Pkg.status()
Pkg.instantiate()

using BrickLink;import CSV; using DataFrames; using JSON3; using HTTP; using OAuth; using InfluxDBClient; using Dates

#list of sets
pt = pathof(BrickLink)
fi = normpath(joinpath(pt,"..","set_list.txt"))
sets = CSV.read(fi,DataFrames.DataFrame,header=false)
DataFrames.rename!(sets,Dict(1=>"set_no"));

n_sec_sleep = 3600*6 #every 6 hours
n_sec_sleep_on_failure = 60 #one minute

##############################################################################################################
##############################################################################################################
#credentials
credli = ["ConsumerKey", "ConsumerSecret","TokenValue","TokenSecret","influxtoken"]

cands = ["/root/auth.json"] #docker
fldr =  Sys.iswindows() ? fldr = ENV["USERPROFILE"] : ENV["HOME"]
push!(cands,joinpath(fldr,"auth.json"))
filter!(x->isfile(x),cands)
if length(cands) > 0
    fi = cands[1]
    credentials = JSON3.read(fi);
else 
    #use environment variables    
    credentials = Dict()
    for i in credli
        credentials[i] = get(ENV,i,"")
    end
end

#check credentials
@assert length(credentials) > 0
for k in credli
    @assert haskey(credentials,k)
    @assert length(credentials[k]) > 0
end

INFLUX_USER="bernhard"
INFLUX_ORG="bk"
#note - token is only working for the bricklink bucket
INFLUX_TOKEN = credentials["influxtoken"]
INFLUX_URL = "http://influx.diro.ch"
isett = InfluxDBClient.get_settings(org=INFLUX_ORG,user=INFLUX_USER,url=INFLUX_URL,token=INFLUX_TOKEN);

##############################################################################################################
##############################################################################################################

##############################################################################################################
#test
setno = "75144" #do not change this (otherwise the size boundaries below may need to be adapted)
setnostring = string(setno) * "-1"
di = Dict("type"=>"SET","no"=>setnostring,"new_or_used"=>"U","currency_code"=>"CHF") #U for used, N for new
di_new = deepcopy(di)
di_new["new_or_used"] = "N"

dftestu = get_prices(credentials,di)
dftestn = get_prices(credentials,di_new)
@assert dftestu[1,:new_or_used] == "U"
@assert dftestu[1,:x1] > 0
@assert dftestu[1,:x1] > 10
@assert dftestu[1,:x1] < 100_0000
@assert size(dftestu,2) > 15 #at least a few prices should be there

#same checks for dftestn
@assert dftestn[1,:new_or_used] == "N"
@assert dftestn[1,:x1] > 0
@assert dftestn[1,:x1] > 10
@assert dftestn[1,:x1] < 100_0000
@assert size(dftestn,2) > 25 #at least a few prices should be there

@assert size(sets,1) > 0

##############################################################################################################
##############################################################################################################
function inf_loop(sets,credentials,di,di_new,isett,n_sec_sleep_on_failure,n_sec_sleep)
    loop_counter = 0

    @info("Starting infinite while loop...")
    while true
        if loop_counter == 0
            #small batch for testing
            szmax = min(3,size(sets,1))
            main(sets[1:szmax,:],credentials,di,di_new,isett,n_sec_sleep_on_failure,10)
        else
            main(sets,credentials,di,di_new,isett,n_sec_sleep_on_failure,n_sec_sleep)
        end
    
        loop_counter += 1
    end
    return nothing 
end

@info("Starting infinite loop...")
inf_loop(sets,credentials,di,di_new,isett,n_sec_sleep_on_failure,n_sec_sleep)
