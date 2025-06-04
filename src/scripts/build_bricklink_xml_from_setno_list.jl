setno_list = ["75254-1",
"75177-1",
"75168-1",
"75176-1",
"75148-1",
"75306-1",
"75338-1",
"75153-1",
"75152-1",
"75170-1",
"75249-1",
"75165-1",
"75164-1",
"75100-1",
"75180-1",
"75104-1",
"75187-1"]

setno_list

#itemid_list = get_item_id.(setno_list)

core = mapreduce(item_text,*,setno_list)

txt = """<INVENTORY>""" * core * """</INVENTORY>"""

# write to txt file
fi = raw"c:\temp\bricklink.xml"
isfile(fi) && rm(fi)
open(fi, "w") do io
    write(io, txt)
end
