package V_ALU;
	import Vector :: * ;
	import V_Decoder :: * ;
	
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
		let c_i = a_i * b_i;
		return truncate(pack(c_i));
	endfunction

	function Bit#(n) sat_add (Bit#(n) a, Bit#(n) b);
		Int#(n) a_i = unpack(a);
		Int#(n) b_i = unpack(b);
		Int#(n) c_i = boundedPlus(a_i,b_i);
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

	function Bit#(64) computeAtVecSize(Bit#(64) reg1, Bit#(64) reg2, Bit#(5) imm, V_arith_instr inst, Bit#(vsize) _) //Todo, could fetch imm from inst
	provisos(Div#(64,vsize,v_n), Add#(a__, vsize, 64), Mul#(TDiv#(64, vsize), vsize, 64), Add#(b__, 5, vsize));

		function Bit#(vsize) func(Bit#(vsize) a, Bit#(vsize) b) = add(a,b);

                case (inst.op) matches //For further extensions, should depend on encoding, todo: maybe match on pair?
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

		if (inst.encoding == OP_IVX || inst.encoding == OP_IVI || inst.encoding == OP_MVX) begin
			let vsize = valueOf(vsize);
			let n=64/vsize;
			Int#(5) imm_s = unpack(imm); //Only does signed atm
			Bit#(vsize) val = (inst.encoding == OP_IVI)?pack(signExtend(imm_s)):truncate(reg1);
			Vector#(v_n,Bit#(vsize)) v = unpack(0);
			for(Integer i=0; i<valueOf(v_n); i=i+1) begin
				v[i]=val;
			end
			Bit#(64) reg1_cloned = pack(v);
			return computeFunc(reg2, reg1_cloned, func);
		end
		else
			return computeFunc(reg2, reg1, func);
	endfunction

	function Bit#(64) get_element_zeroextended(Bit#(64) vec, Bit#(7) index, V_size size);
		Bit#(7) esize = zeroExtend(pack(size));
		let no_of_elements = 64 / esize;
		let left_els = no_of_elements - (index+1);
		let pruned_vec = vec;
		pruned_vec = pruned_vec << (left_els*esize);
		pruned_vec = pruned_vec >> 64-esize;
		return pruned_vec;
	endfunction

	//Get last vector element zero extended
	function Bit#(64) get_last_vec_el_ze(Bit#(64) vec, V_size size);
		Bit#(10) esize = get_size_of_sew(size);
		let pruned_vec = vec >> 64-esize;
		return pruned_vec;
	endfunction

	//Use should pattern match on enum in decoder ideally! That way we can add more sizes easily
	function Bit#(64) vector_compute(Bit#(64) reg1, Bit#(64) reg2, Bit#(5) imm, V_arith_instr inst, V_size vsew);
			//Todo: Automate me
			case (vsew) matches
				tagged Bit_8: begin
					Bit#(8) in = 0;
					return computeAtVecSize(reg1, reg2, imm, inst, in);	
				end
				tagged Bit_16: begin
					Bit#(16) in = 0;
					return computeAtVecSize(reg1, reg2, imm, inst, in);	
				end
				tagged Bit_32: begin
					Bit#(32) in = 0;
					return computeAtVecSize(reg1, reg2, imm, inst, in);
				end
			endcase
	endfunction
endpackage
