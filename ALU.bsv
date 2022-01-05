package ALU;
	import Vector :: * ;
	import Decoder :: * ;

	interface ALU;
		method Bit#(64) compute(Bit#(64) reg1, Bit#(64) reg2, V_arith_instr inst_type);
	endinterface

	function Bit#(n) add (Bit#(n) a, Bit#(n) b);
		Int#(n) a_i = unpack(a);
		Int#(n) b_i = unpack(b);
		Int#(n) c_i = a_i + b_i;
		return pack(c_i);
	endfunction

	function Bit#(n) sub (Bit#(n) a, Bit#(n) b);
		Int#(n) a_i = unpack(a);
		Int#(n) b_i = unpack(b);
		Int#(n) c_i = a_i - b_i;
		return pack(c_i);
	endfunction

	function Bit#(n) mult (Bit#(n) a, Bit#(n) b);
		Int#(n) a_i = unpack(a);
		Int#(n) b_i = unpack(b);
		Int#(n) c_i = a_i * b_i;
		return pack(c_i);
	endfunction

	function Bit#(n) sat_add (Bit#(n) a, Bit#(n) b);
		Int#(n) a_i = unpack(a);
		Int#(n) b_i = unpack(b);
		Int#(n) c_i = satPlus(Sat_Bound,a_i,b_i);
		return pack(c_i);
	endfunction

	function Bit#(n) sat_sub (Bit#(n) a, Bit#(n) b);
		Int#(n) a_i = unpack(a);
		Int#(n) b_i = unpack(b);
		Int#(n) c_i = satMinus(Sat_Bound,a_i,b_i);
		return pack(c_i);
	endfunction


	function Bit#(64) computeFunc(Bit#(64) reg1, Bit#(64) reg2, function Bit#(vsize) f(Bit#(vsize) a, Bit#(vsize) b))
	provisos(Div#(64,vsize,v_n), Add#(a__, vsize, 64), Bits#(Vector::Vector#(v_n, Bit#(vsize)), 64));
		Vector#(v_n,Bit#(vsize)) v1=unpack(reg1);
		Vector#(v_n,Bit#(vsize)) v2=unpack(reg2);

		Vector#(v_n,Bit#(vsize)) v_c = zipWith(f, v1, v2);
		
		return pack(v_c);
	endfunction

	function Bit#(64) computeAtVecSize(Bit#(64) reg1, Bit#(64) reg2, V_arith_instr inst, Bit#(vsize) _)
	provisos(Div#(64,vsize,v_n), Add#(a__, vsize, 64), Mul#(TDiv#(64, vsize), vsize, 64));

		function Bit#(vsize) func(Bit#(vsize) a, Bit#(vsize) b) = add(a,b);

                case (inst.op) matches
                	tagged Op_add:
                		func = add;
                	tagged Op_sub:
                		func = sub;
                	tagged Op_mult:
                		func = mult;
                	tagged Op_sat_add:
                		func = sat_add;
                	tagged Op_sat_sub:
                		func = sat_sub;
                	endcase

		if (inst.encoding == OP_IVX || inst.encoding == OP_IVI) begin
			let vsize = valueOf(vsize);
			let n=64/vsize;
			Vector#(v_n,Bit#(vsize)) v = unpack(reg1);
			for(Integer i=1; i<valueOf(v_n); i=i+1) begin
				v[i]=v[0];
			end
			Bit#(64) reg1_cloned = pack(v);
			return computeFunc(reg1_cloned, reg2, func);
		end
		else
			return computeFunc(reg1, reg2, func);
	endfunction

	//Use should pattern match on enum in decoder ideally! That way we can add more sizes easily
	(* synthesize *)
	module mkALU(ALU);
		method Bit#(64) compute(Bit#(64) reg1, Bit#(64) reg2, V_arith_instr inst_type);
			//Todo: Automate me
			case (inst_type.v_size) matches
				tagged Bit_16: begin
					Bit#(16) in = 0;
					return computeAtVecSize(reg1, reg2, inst_type, in);	
				end
				tagged Bit_32: begin
					Bit#(32) in = 0;
					return computeAtVecSize(reg1, reg2, inst_type, in);
				end
			endcase
		
		endmethod
	endmodule
endpackage
