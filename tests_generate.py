import itertools

out = ""

instructions = {"VSUB": ["0b","20","81","57"]}

with open('tests.plain') as f:
    for instr,val1_str,val2_str,out_str in zip(f,f,f,f):
        out += "X" #Probing char
        out +=  "".join([chr(int(x,16)) for x in reversed(["AA","BB","CC","DD"])])
        out +=  "".join([chr(int(x,16)) for x in reversed(val1_str.split(" "))])
        out +=  "".join([chr(int(x,16)) for x in reversed(val2_str.split(" "))])
        out +=  "".join([chr(int(x,16)) for x in reversed(out_str.split(" "))])

text_file = open("tests.dat", "w")
n = text_file.write(out)
text_file.close()