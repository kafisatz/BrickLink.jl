#https://fxds-public-exchange-rates-api.oanda.com/cc-api/currencies?base=EUR&quote=CHF&data_type=general_currency_pair&start_date=2025-01-23&end_date=2025-01-24
export fxrate
function fxrate(from;to="CHF") 
#https://fxds-public-exchange-rates-api.oanda.com/cc-api/currencies?base=EUR&quote=CHF&data_type=general_currency_pair&start_date=2025-01-23&end_date=2025-01-24
    #from="EUR"
    td = today()
    yd = td - Day(1)
    url = "https://fxds-public-exchange-rates-api.oanda.com/cc-api/currencies?base=$(from)&quote=$(to)&data_type=general_currency_pair&start_date=$(yd)&end_date=$(td)"
    rs = HTTP.get(url)
    js = JSON3.read(rs.body)
    
    v = (js.response[1].average_ask) # + js.response[1].average_bid)/2
    v2 = parse(Float64,v)
    return v2
end