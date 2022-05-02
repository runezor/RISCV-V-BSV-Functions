import V_Decoder::*;
import V_ALU::*;
import Vector :: * ;

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

        Vector#(4, Bit#(8)) ts_vec = unpack(0);
        for(Integer j=0; j<4; j=j+1) begin
            int temp <-$fgetc( file );
            ts_vec[j] =  truncate(pack(temp));
        end
		instr <= pack(ts_vec);
        
        Vector#(8, Bit#(8)) t_vec = unpack(0);
        for(Integer j=0; j<8; j=j+1) begin
            int temp <-$fgetc( file );
            t_vec[j] =  truncate(pack(temp));
        end
		val1 <= pack(t_vec);

        for(Integer j=0; j<8; j=j+1) begin
            int temp <-$fgetc( file );
            t_vec[j] =  truncate(pack(temp));
        end
		val2 <= pack(t_vec);

        for(Integer j=0; j<8; j=j+1) begin
            int temp <-$fgetc( file );
            t_vec[j] =  truncate(pack(temp));
        end
		result <= pack(t_vec);

              
        
        if ( i == -1)
            begin
                $display("Could not get from");
                $fclose(file);
                $finish(0);
            end
        
    endrule

	rule runInstruction( state==1 && instr!=0 );
        $display("Instruction: %h", instr);
        $display("Val 1: %h %", val1);
        $display("Val 2: %h", val2);
        $display("Result: %h", result);
        $display("Instruction binary: %b", instr);
        $display("Val 1 binary: %b / %", val1);
        $display("Val 2 binary: %b / %", val2);
        $display("Result binary: %b", result);
    endrule

endmodule
