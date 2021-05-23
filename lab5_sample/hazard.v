`include "opcodes.v"

module hazard_detect(IFID_IR, IDEX_rd, IDEX_M_MemRead, is_stall);

	input [`WORD_SIZE-1:0] IFID_IR;
	input [1:0]  IDEX_rd;
	input IDEX_M_MemRead;
	output is_stall;

	assign opCode = IFID_IR[15:12];
	assign ID_rs1 = IFID_IR[11:10];
	assign ID_rs2 = IFID_IR[9:8];
	assign InstFunc = IFID_IR[5:0];

	wire readRs1;
	wire readRs2;

	// R-type ALU
	// rs2 not read : NOT, TCP, SHL, SHR, WWD
	// rs1, rs2 not read : HLT
	// I-type
	// rs2 not read : ADI, ORI, LWD, 
	// rs1, rs2 not read : LHI, 
	// Branch
	// rs2 not read : BGZ, BLZ
	// jump
	// rs2 not read : JPR, JRL (R-type)
	// rs1, rs2 not read : JMP, JAL
	// others : rs1, rs2 either read

	assign readRs1 = ((opCode == `ALU_OP) && (InstFunc != `INST_FUNC_HLT)) || (opCode == `ADI_OP) || (opCode == `ORI_OP) || (opCode == `LWD_OP)
			|| (opCode == `SWD_OP) || (opCode == `BNE_OP) || (opCode == `BEQ_OP) || (opCode == `BGZ_OP) || (opCode == `BLZ_OP);
	assign readRs2 = ((opCode == `ALU_OP) && ((InstFunc == `INST_FUNC_ADD) || (InstFunc == `INST_FUNC_SUB) || 
			(InstFunc == `INST_FUNC_AND) || (InstFunc == `INST_FUNC_ORR))) || 
			(opCode == `SWD_OP) || (opCode == `BNE_OP) || (opCode == `BEQ_OP);

	assign is_stall = IDEX_M_MemRead && ((readRs1 && (ID_rs1 == IDEX_rd)) || (readRs2 && (ID_rs2 == IDEX_rd)));
	

endmodule