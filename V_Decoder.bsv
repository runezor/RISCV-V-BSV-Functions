package V_Decoder;
	typedef enum {Op_v,Load_fp,Store_fp} Opcode;
	typedef enum {Op_add = 0, Op_sub = 2, Op_mult = 5, Op_sat_add = 33, Op_sat_sub = 35} V_arith_op deriving (Eq, Bits);
	typedef enum {Bit_16 = 16, Bit_32 = 32} V_size deriving(Eq, Bits);
	typedef enum {OP_VV = 0, OP_FVV = 1, OP_MVV = 2, OP_IVI = 3, OP_IVX = 4, OP_FVF = 5, OP_MVX = 6, OP_CFG = 7} V_arith_encoding deriving(Eq, Bits); //TODO: Should encode unsigned/2bit complement
	
	typedef struct {
		Bit#(5) addr;
	} Register_addr deriving (Eq, Bits);

	typedef struct {
		Bit#(5) value;
	} Immediate deriving (Eq, Bits);

	typedef union tagged {
		Register_addr Payload_addr;
		Immediate Payload_immediate;
	} V_payload deriving (Eq, Bits);

	typedef struct {
		V_arith_op op;
		V_size v_size;
		V_arith_encoding encoding;
		V_payload load1;
		Register_addr load2;
		Register_addr dest;
	} V_arith_instr deriving (Bits);

	typedef struct {
		Bit#(32) location;
	} V_load_instr deriving (Bits);

	typedef struct {
	} V_invalid_instr deriving (Bits);

	typedef struct {
		Bit#(32) location;
	} V_store_instr deriving (Bits);

	typedef union tagged {
		V_arith_instr Arith;
		V_load_instr Load;
		V_store_instr Store;
		V_invalid_instr Invalid;
	} V_instr deriving (Bits);

	export V_instr;
	export v_decode;

	function V_instr v_decode(Bit#(32) inst);
			let opcode = inst[6:0];
			let opcode_1 = inst[4:2];
			let opcode_2 = inst[6:5];
			let dest = inst[11:7];
			let vs2 = inst[24:20];
			let vs1 = inst[19:15];
			let vm = inst[25];
			let funct6 = inst[31:26];
			let funct3 = inst[14:12];

			let load_fp = (opcode_1 == 1 && opcode_2 == 0);
			let store_fp = (opcode_1 == 1 && opcode_2 == 1);
			let op_v = (opcode == 87);

			V_instr instr = tagged Invalid V_invalid_instr {};

			V_invalid_instr invalid = V_invalid_instr {};
			instr = tagged Invalid invalid;

			V_arith_encoding v_enc = unpack(funct3);
			V_arith_op v_op = unpack(funct6);

			V_payload vs1_payload;
			if (v_enc == OP_IVI)
				vs1_payload = tagged Payload_immediate Immediate {value: vs1};
			else
				vs1_payload = tagged Payload_addr Register_addr {addr: vs1};
			Register_addr vs2_addr = Register_addr{addr: vs2};
			Register_addr dest_addr = Register_addr{addr: dest};


			if (load_fp)
				instr = tagged Load V_load_instr {location: 0};
			if (store_fp)
				instr = tagged Store V_store_instr {location: 0};
			if (op_v)
				instr = tagged Arith V_arith_instr {op: v_op, v_size: Bit_16, encoding: v_enc, load1:vs1_payload, load2:vs2_addr,dest: dest_addr};

			return instr;
	endfunction
endpackage
