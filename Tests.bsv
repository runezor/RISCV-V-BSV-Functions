import Decoder::*;
import ALU::*;
import List :: * ;

interface Printer;
	method Action print_instr(V_instr i);
endinterface : Printer


(* synthesize *)
module mkTests();

	Decoder decoder <- mkDecoder();
	ALU alu <- mkALU();


	Reg#(Bit#(32)) instr <- mkReg(0);
	Reg#(Bit#(32)) i <- mkReg(0);

	rule readFromList( True );
		//This is pretty grim but I can't for the life of me figure out how to make lists work in Bluespec
		List #(Bit#(32)) instructions = replicate (5, 32'd1);
			instructions[0] = 'h02840457;
			instructions[1] = 'h02813457;
			instructions[2] = 31;
			instructions[3] = 41;
			instructions[4] = 51;

		Bit#(32) l = fromInteger(length(instructions));
		if (i==l) begin
			$display("END");
			$finish(0);
		end

		Bit#(32) n = instructions[i];
		instr <= n;
		i <= i + 1;
	endrule

	rule decode( True);
		$display("--------------------------------------");
		$display("Decoding instruction: %b", instr);
		$display("--------------------------------------");
		let i = decoder.decode(instr);
		case (i) matches
                        tagged Arith .a: begin
				$display("Arithmetic type instruction detected");
				V_arith_instr b = a;
				$display("Arith opcode is %d",b.op); //Would much rather print b.op.name()
				$display("Encoding is %d", b.encoding);
				Bit#(64) vs2 = zeroExtend(b.load2.addr);
				Bit#(64) vs1 = 0;
				case (b.load1) matches
					tagged Payload_immediate .payload: begin
						vs1 = zeroExtend(payload.value);
					end
					tagged Payload_addr .payload: begin
						vs1 = zeroExtend(payload.addr);
					end
				endcase
				$display("vs1 refers to address/imm %d", vs1);
				$display("vs2 refers to address %d", vs2);
				$display("dest refers to address %d", b.dest);
				$display("Using register model: rs(x)=x");
				Bit#(64) res = alu.compute(vs1,vs2,b);
				$display("ALU output is %b", res);
			end
			tagged Invalid .a : begin $display("Invalid instruction"); end
		endcase
		$display("\n");
	endrule

endmodule
