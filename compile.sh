bsc -verilog V_Decoder.bsv
bsc -verilog V_ALU.bsv
bsc -verilog Tests.bsv
bsc -o sim -e mkTests mkTests.v 
./sim