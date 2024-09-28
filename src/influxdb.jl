export write_to_influxdb
function write_to_influxdb(df_in::DataFrames.DataFrame,isett)
    
    dt = Dates.now()
    df = deepcopy(df_in)
    nms = names(df)
    pricenames = filter(x->startswith(x,"x"),nms)
    lastpricename = pricenames[end]
    nprices = parse(Int,lastpricename[2:end])
    @assert nprices > 0
    @assert nprices < 3_000

    df[!,:item2] = map(x->x[1:end-2],df[!,:item])
    
    dfinflux = DataFrames.DataFrame()
    #i=1
    for i=1:size(df,1)
        rec = df[i,:]
        count = 1
        set = rec[:item2]
        while (!ismissing(rec["x"*string(count)]) && count < nprices)
            price = rec["x"*string(count)]
            dftmp = DataFrames.select(DataFrames.DataFrame(rec),[:item2,:type,:name,:new_or_used,:currency])
            dftmp[!,:price] .= price
            append!(dfinflux,dftmp)
            count += 1
        end
    end

    #write to db 
    batchsize = 100
    bkt="bricklink"
    DataFrames.rename!(dfinflux, :item2 => :setno)
    dfinflux[!,:datetime] .= dt
    @show size(dfinflux)
    rs,lp = write_dataframe(settings=isett,batchsize=batchsize,bucket=bkt,measurement="prices",data=dfinflux,fields=["currency","name","price"],timestamp=:datetime,tags=String["type","currency","setno","new_or_used"],tzstr = "Europe/Berlin",compress=true);

    #select minimum price per set
    dfinflux_min_price = DataFrames.combine(DataFrames.groupby(dfinflux, [:setno,:name,:type,:new_or_used,:currency]), :price => minimum => :price)
    dfinflux_min_price[!,:datetime] .= dt
    @show size(dfinflux_min_price)
    rs,lp = write_dataframe(settings=isett,batchsize=batchsize,bucket=bkt,measurement="minimum_price",data=dfinflux_min_price,fields=["currency","name","price"],timestamp=:datetime,tags=String["type","currency","setno","new_or_used"],tzstr = "Europe/Berlin",compress=true);

    return nothing 
end
