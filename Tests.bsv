import V_Decoder::*;
import V_ALU::*;

(* synthesize *)
module mkTests();

	Reg#(Bit#(32)) instr <- mkReg(0);
	Reg#(Bit#(64)) val1 <- mkReg(0);
	Reg#(Bit#(64)) val2 <- mkReg(0);
	Reg#(Bit#(64)) result <- mkReg(0);
	Reg#(File) file <- mkReg(InvalidFile);
	Reg#(Bit#(1)) state <- mkReg(0);


	rule start( state==0 );
        String readFile = "tests.dat";
        File f <- $fopen(readFile, "r" );
        file <= f;
        state <= 1;
    endrule

	rule readFromList( state==1 );

        int i <- $fgetc( file );
        int v1_1 <- $fgetc( file );
        int v1_2 <- $fgetc( file );
        int v2_1 <- $fgetc( file );
        int v2_2 <- $fgetc( file );
        int res_1 <- $fgetc( file );
        int res_2 <- $fgetc( file );
        
        if ( i != -1)
            begin
                instr <= truncate( pack(i) );
                val1 <=  {pack(v1_1),pack(v1_2)};
                val2 <= {pack(v2_1),pack(v2_2)};
                result <= {pack(res_1),pack(res_2)};
            end
        else // error
            begin
                $display("Could not get from");
                $fclose(file);
                $finish(0);
            end
        
    endrule

	rule runInstruction( state==1 && instr!=0 );
        $display("Instruction: %b", instr);
        $display("Val 1: %b", val1);
        $display("Val 2: %b", val2);
        $display("Result: %b", result);
    endrule

endmodule
