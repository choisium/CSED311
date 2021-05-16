`include "opcodes.v"


module hazard_detect(IFID_IR, IDEX_rd, use_rs, use_rt, IDEX_M_mem_read, is_stall);
	
	// Stall with forwarding
	input [`WORD_SIZE-1:0] IFID_IR;
	input [1:0]  IDEX_rd;
	input use_rs, use_rt;
	input IDEX_M_mem_read;

	output reg is_stall;

	wire [1:0] IFID_rs, IFID_rt;

	assign IFID_rs = IFID_IR[11:10];
	assign IFID_rt = IFID_IR[9:8];

	always @(*) begin
	 	is_stall = (((IFID_rs == IDEX_rd) && use_rs) 
		 || ((IFID_rt == IDEX_rd) && use_rt)) && IDEX_M_mem_read ? 1:0;
	end
	
endmodule
