package V_Decoder;
	typedef enum {Op_v,Load_fp,Store_fp} Opcode;
	typedef enum {Op_add = 0, Op_sub = 2, Op_sat_addu = 32, Op_sat_subu = 34} V_arith_op_i1 deriving (Eq, Bits);
	typedef enum {Op_mult = 37} V_arith_op_i2 deriving (Eq, Bits);
	typedef enum {Op_invalid = 63} V_arith_op_fp deriving (Eq, Bits);
	typedef enum {Bit_8 = 0, Bit_16 = 1, Bit_32 = 2, Bit_64 = 3, Bit_128=4} V_el_size deriving(Eq, Bits);
	typedef enum {OP_VV = 0, OP_FVV = 1, OP_MVV = 2, OP_IVI = 3, OP_IVX = 4, OP_FVF = 5, OP_MVX = 6, OP_CFG = 7} V_funct3 deriving(Eq, Bits);
	
	typedef struct {
		Bit#(5) addr;
	} Register_addr deriving (Eq, Bits);

	typedef struct {
		Bit#(5) value;
	} Immediate deriving (Eq, Bits);

	typedef union tagged {
		Register_addr Payload_addr_GPR;
		Register_addr Payload_addr_vec;
		Immediate Payload_immediate;
	} V_payload deriving (Eq, Bits);

	typedef union tagged {
		V_arith_op_i1 V_arith_op_i1;
		V_arith_op_i2 V_arith_op_i2;
		V_arith_op_fp V_arith_op_fp;
	} V_arith_op deriving (Eq, Bits);

	typedef struct {
		V_arith_op op;
		V_payload load1;
		Register_addr load2;
		Register_addr dest;
	} V_arith_instr deriving (Bits);

	//NOT A COMPLETE DECODING
	typedef struct {
		Bit#(5) dest;
		V_el_size vsew;
	} V_vsetvl_instr deriving (Bits);

	typedef struct {
		Bit#(5) dest;
		Bit#(5) rs1;
	} V_load_instr deriving (Bits);

	typedef struct {
	} V_invalid_instr deriving (Bits);

	typedef struct {
		Bit#(5) vs3;
		Bit#(5) rs1;
	} V_store_instr deriving (Bits);

	typedef union tagged {
		V_arith_instr Arith_V_instr;
		V_vsetvl_instr Vsetvl_V_instr;
		V_load_instr Load_V_instr;
		V_store_instr Store_V_instr;
		V_invalid_instr Invalid_V_instr;
	} V_instr deriving (Bits);

	export V_Decoder::*;

	function V_instr v_decode(Bit#(32) inst);
			//For standard format
			let opcode = inst[6:0];
			let dest = inst[11:7];
			let vs2 = inst[24:20];
			let vs1 = inst[19:15];
			let vm = inst[25];
			let funct6 = inst[31:26];
			let funct3 = inst[14:12];
			//For vsetvli
			let zimm = inst[30:20];			
			let vsew = zimm[4:2];
			//For memory
			let load_fp = (opcode == 7) ;	
			let store_fp = (opcode == 39);
			let op_v = (opcode == 87);

			V_instr instr = tagged Invalid_V_instr V_invalid_instr {};

			V_funct3 v_funct3 = unpack(funct3);

			if (load_fp)
				instr = tagged Load_V_instr V_load_instr {rs1: vs1, dest: dest};
			if (store_fp)
				instr = tagged Store_V_instr V_store_instr {rs1: vs1, vs3: dest};
			if (op_v) begin				
				V_arith_op v_op = ?;
				if (v_funct3 == OP_VV || v_funct3 == OP_IVX || v_funct3 == OP_IVI)
					v_op = tagged V_arith_op_i1 unpack(funct6);
				if (v_funct3 == OP_MVV || v_funct3 == OP_MVX)
					v_op = tagged V_arith_op_i2 unpack(funct6);
				if (v_funct3 == OP_FVV || v_funct3 == OP_FVF)
					v_op = tagged V_arith_op_fp unpack(funct6);
					
				Bool scalar = (v_funct3 == OP_IVX || v_funct3 == OP_IVI || v_funct3 == OP_MVX || v_funct3 == OP_FVF);

				V_payload vs1_payload;

				if (v_funct3 == OP_IVI)
					vs1_payload = tagged Payload_immediate Immediate {value: vs1};
				else if (v_funct3==OP_VV || v_funct3==OP_MVV)
					vs1_payload = tagged Payload_addr_vec Register_addr {addr: vs1};
				else
					vs1_payload = tagged Payload_addr_GPR Register_addr {addr: vs1};

				Register_addr vs2_addr = Register_addr{addr: vs2};
				Register_addr dest_addr = Register_addr{addr: dest}; 

				if (v_funct3 == OP_CFG)
					instr = tagged Vsetvl_V_instr V_vsetvl_instr {dest: dest, vsew: unpack(vsew)};
				else
					instr = tagged Arith_V_instr V_arith_instr {op: v_op, load1:vs1_payload, load2:vs2_addr,dest: dest_addr};
			end
			return instr;
	endfunction
endpackage
