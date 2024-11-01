sets

mf = get_minifigs("75125-1",credentials)
mf = get_minifigs("7181-1",credentials)
mf = get_minifigs("75397-1",credentials)
setno="75397-1"


setnos = map(x->string(x)*"-1",sets.set_no)

setnos_SHORT = setnos[1:13]
mfs = get_minifigs(setnos_SHORT,credentials)

#20 seconds for 150 sets ~ 450 minifigs
@time mf = get_minifigs(setnos,credentials)

CSV.write(raw"C:\temp\minifigs_which_we_should_have.csv",mf)


