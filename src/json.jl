#

export jwrite 
function jwrite(x,fi)
    @assert isdir(splitdir(fi)[1])
    # write a pretty file
    open(fi, "w") do f
        JSON3.pretty(f, JSON3.write(x))
        println(f)
    end
    return nothing 
end