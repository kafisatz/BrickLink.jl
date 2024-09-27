export main
function main(sets,credentials,di,di_new,isett,n_sec_sleep_on_failure,n_sec_sleep)

    try 
        #get data
        #used
            df_used = get_prices(credentials,di,sets)
        #new prices
            df_new = get_prices(credentials,di_new,sets)

        #merge used and new prices
        df = append!(deepcopy(df_used),df_new,cols=:union)

        #write to influxdb
        write_to_influxdb(df,isett)
        
        @info("Success: $(Dates.now()). Next iteration in $(round(n_sec_sleep/3600,digits=3)) hours")
        sleep(n_sec_sleep)
    catch error271
         @show error271
         @warn("Failed. See above. Retrying in $(n_sec_sleep_on_failure) seconds.")
         sleep(n_sec_sleep_on_failure)
    end
    
    return nothing
end