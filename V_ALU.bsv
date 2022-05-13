`define VLEN 128

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

	function Bit#(n) sat_addu (Bit#(n) a, Bit#(n) b);
		UInt#(n) a_i = unpack(a);
		UInt#(n) b_i = unpack(b);
		UInt#(n) c_i = boundedPlus(a_i,b_i);
		return pack(c_i);
	endfunction

	function Bit#(n) sat_subu (Bit#(n) a, Bit#(n) b);
		UInt#(n) a_i = unpack(a);
		UInt#(n) b_i = unpack(b);
		UInt#(n) c_i = boundedMinus(a_i,b_i);
		return pack(c_i);
	endfunction

	function Bit#(`VLEN) computeFunc(Bit#(`VLEN) reg1, Bit#(`VLEN) reg2, function Bit#(sew) f(Bit#(sew) a, Bit#(sew) b))
	provisos(Div#(`VLEN,sew,v_n), Add#(a__, sew, `VLEN), Bits#(Vector::Vector#(v_n, Bit#(sew)), `VLEN));
		Vector#(v_n,Bit#(sew)) v1=unpack(reg1);
		Vector#(v_n,Bit#(sew)) v2=unpack(reg2);

		Vector#(v_n,Bit#(sew)) v_c = zipWith(f, v1, v2);
		
		return pack(v_c);
	endfunction

	function Bit#(`VLEN) scalar_to_vec(Bit#(sew) val)
	provisos(Div#(`VLEN,sew,v_n), Add#(a__, sew, `VLEN), Mul#(TDiv#(`VLEN, sew), sew, `VLEN), Add#(b__, 5, sew));
		let sew = valueOf(sew);

		Vector#(v_n,Bit#(sew)) v = unpack(0);
		for(Integer i=0; i<valueOf(v_n); i=i+1) begin
			v[i]=val;
		end

		return pack(v);
	endfunction

	function Bit#(`VLEN) compute_vec_at_size(Bit#(`VLEN) reg1, Bit#(`VLEN) reg2, V_arith_instr instr, Bit#(sew) _) //Todo, could fetch imm from inst
	provisos(Div#(`VLEN,sew,v_n), Add#(a__, sew, `VLEN), Mul#(TDiv#(`VLEN, sew), sew, `VLEN), Add#(b__, 5, sew));
		function Bit#(sew) func(Bit#(sew) a, Bit#(sew) b) = add(a,b);

		case (instr.op) matches
			tagged V_arith_op_i1 .i1: begin
				case (i1) matches
                	tagged Op_add:
                		func = add;
                	tagged Op_sub:
                		func = sub;
                	tagged Op_sat_addu:
                		func = sat_addu;
                	tagged Op_sat_subu:
                		func = sat_subu;
				endcase
			end 
			tagged V_arith_op_i2 .i2: begin
				case (i2) matches
                	tagged Op_mult:
                		func = mult;
				endcase
			end 
		endcase

		let val1 = reg1;
		case (instr.load1) matches //Handles scalar input logic
			tagged Payload_immediate .p: begin
				Int#(5) imm_s = unpack(p.value);
				Bit#(sew) imm_ex = pack(instr_is_signed(instr)?
					signExtend(imm_s):zeroExtend(imm_s));
				val1 = scalar_to_vec(imm_ex);
			end
			tagged Payload_addr_GPR .*: begin
				Bit#(sew) rs1_t = truncate(reg1);
				val1 = scalar_to_vec(rs1_t);
			end
		endcase

		return computeFunc(reg2, val1, func);
	endfunction

	function Bit#(10) get_size_of_sew(V_el_size s);
			return (8<<pack(s));
	endfunction


	function Bit#(`VLEN) get_vec_el_ze(Bit#(`VLEN) vec, Bit#(10) index, V_el_size size);
		Bit#(10) esize = get_size_of_sew(size);
		let no_of_elements = `VLEN / esize;
		let left_els = no_of_elements - (index+1);
		let pruned_vec = vec;
		pruned_vec = pruned_vec << (left_els*esize);
		pruned_vec = pruned_vec >> `VLEN-esize;
		return pruned_vec;
	endfunction

	//Get last vector element zero extended
	function Bit#(`VLEN) get_last_vec_el_ze(Bit#(`VLEN) vec, V_el_size size);
		let no_of_elements = `VLEN / get_size_of_sew(size);
		return get_vec_el_ze(vec, no_of_elements-1, size);
	endfunction

	//Use should pattern match on enum in decoder ideally! That way we can add more sizes easily
	function Bit#(`VLEN) vector_compute(Bit#(`VLEN) reg1, Bit#(`VLEN) reg2, V_arith_instr instr, V_el_size sew);
			//Todo: Automate me
			case (sew) matches
				tagged Bit_8: begin
					Bit#(8) in = 0;
					return compute_vec_at_size(reg1, reg2, instr, in);	
				end
				tagged Bit_16: begin
					Bit#(16) in = 0;
					return compute_vec_at_size(reg1, reg2, instr, in);	
				end
				tagged Bit_32: begin
					Bit#(32) in = 0;
					return compute_vec_at_size(reg1, reg2, instr, in);
				end
			endcase
	endfunction
endpackage
