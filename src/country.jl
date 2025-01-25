export countrydict 
function countrydict(ctryfi);
    c = CSV.read(ctryfi,DataFrame)
    countryToContinentDict  = Dict(c.Country .=> c.Continent)
    return countryToContinentDict
end

