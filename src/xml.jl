export item_text 
function item_text(itemno::String;item_type="S")

#value must be one of the following: S (for a set), P (for a part), M (for a minifigure), B (for a book), G (for a gear item), C (for a catalog), I (for an instruction manual), or O (for an original box)
allowed_item_types=["P","S","M","B","G","C","I","O"]
@assert in(item_type,allowed_item_types)

p1 = """
<ITEM>
<ITEMTYPE>"""
p2="""</ITEMTYPE>
<ITEMID>"""
p3="""</ITEMID>
<MINQTY>1</MINQTY>
</ITEM>
"""

txt = p1 * item_type * p2 * itemno * p3

return txt 
end