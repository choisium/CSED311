`include "opcodes.v"


module hazard_detect(IFID_IR, IDEX_rd, use_rs, use_rt, IDEX_M_mem_read, is_stall);
	
	// Stall with forwarding
	input [`WORD_SIZE-1:0] IFID_IR;
	input [1:0]  IDEX_rd;
	input use_rs, use_rt;
	input IDEX_M_mem_read;

	output is_stall;

	wire [1:0] IFID_rs, IFID_rt;

	assign IFID_rs = IFID_IR[11:10];
	assign IFID_rt = IFID_IR[9:8];

	assign is_stall = (((IFID_rs == IDEX_rd) && use_rs) || ((IFID_rt == IDEX_rd) && use_rt)) && IDEX_M_mem_read;
	
endmodule

// stall without forwarding 
/* 
module hazard_detect(ID_rs, ID_rt, EX_rd, MEM_rd, WB_rd, EX_regwrite, MEM_regwrite, WB_regwrite,
					 use_rs, use_rt, IDEX_M_mem_read, is_stall);

	input [1:0]  ID_rs, ID_rt;
	input [1:0]  EX_rd, MEM_rd, WB_rd;
	input EX_regwrite, MEM_regwrite, WB_regwrite;
	input use_rs, use_rt;
	input IDEX_M_mem_read;

	output is_stall;

	//TODO: implement hazard detection unit

	wire Stall_rs_EX, Stall_rs_MEM, Stall_rs_WB, Stall_rt_EX, Stall_rt_MEM, Stall_rt_WB;

	assign Stall_rs_EX = (ID_rs == EX_rd) && (use_rs) && EX_regwrite;
	assign Stall_rs_MEM = (ID_rs == MEM_rd) && (use_rs) && MEM_regwrite;
	assign Stall_rs_WB = (ID_rs == WB_rd) && (use_rs) && WB_regwrite;
	assign Stall_rt_EX = (ID_rt == EX_rd) && (use_rt) && EX_regwrite;
	assign Stall_rt_MEM = (ID_rt == MEM_rd) && (use_rt) && MEM_regwrite;
	assign Stall_rt_WB = (ID_rt == WB_rd) && (use_rt) && WB_regwrite;

	assign is_stall = Stall_rs_EX | Stall_rs_MEM | Stall_rs_WB |
				Stall_rt_EX | Stall_rt_MEM | Stall_rt_WB;

endmodule
 */
