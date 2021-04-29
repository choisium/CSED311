`include "opcodes.v" 

module control_unit (opcode, func_code, clk, reset_n, halt, wwd, new_inst, use_rs, use_rt, alu_src, branch, mem_read, mem_write, reg_write, pc_src, reg_dest, reg_src, alu_branch_type, alu_func_code);

	input [3:0] opcode;
	input [5:0] func_code;
	input clk;
	input reset_n;
	
	// additional control signals. halt: to support HLT. wwd: to support WWD. new_inst: new instruction start. use_rs, use_rt: to support hazard detection
	output reg halt, wwd, new_inst, use_rs, use_rt;
	output reg alu_src, branch, mem_read, mem_write, reg_write;
	output reg [1:0] pc_src, reg_dest, reg_src, alu_branch_type;
	output reg [3:0] alu_func_code;

	initial begin
		halt = 0;
		wwd = 0;
		reg_dest = 0;
		use_rs = 0;
		use_rt = 0;
		alu_src = 0;
		branch = 0;
		mem_read = 0;
		mem_write = 0;
		reg_write = 0;
		pc_src = 0;
		reg_src = 0;
		new_inst = 0;
		alu_func_code = 0;
		alu_branch_type = 0;
	end

	// generate control signals
	always @(*) begin
		halt = 0;
		wwd = 0;
		reg_dest = 0;
		use_rs = 0;
		use_rt = 0;
		alu_src = 0;
		branch = 0;
		mem_read = 0;
		mem_write = 0;
		reg_write = 0;
		pc_src = 0;
		reg_src = 0;
		new_inst = 0;

		case(opcode)
			4'd15: begin
				case(func_code)
					`INST_FUNC_ADD, `INST_FUNC_SUB, `INST_FUNC_AND, `INST_FUNC_ORR: begin
						use_rs = 1;
						use_rt = 1;
						reg_write = 1;
						new_inst = 1;
					end
					`INST_FUNC_NOT, `INST_FUNC_TCP, `INST_FUNC_SHL, `INST_FUNC_SHR: begin
						use_rs = 1;
						reg_write = 1;
						new_inst = 1;
					end
					`INST_FUNC_JPR: begin
						use_rs = 1;
						pc_src = 2'b10;
						new_inst = 1;
					end
					`INST_FUNC_JRL: begin
						reg_dest = 2'b10;
						use_rs = 1;
						pc_src = 2'b10;
						reg_write = 1;
						reg_src = 2'b10;
						new_inst = 1;
					end
					`INST_FUNC_WWD: begin
						wwd = 1;
						use_rs = 1;
						new_inst = 1;
					end
					`INST_FUNC_HLT: begin
						halt = 1;
						new_inst = 1;
					end
				endcase
			end
			`ADI_OP, `ORI_OP: begin
				reg_dest = 2'b01;
				use_rs = 1;
				alu_src = 1;
				reg_write = 1;
				new_inst = 1;
			end
			`LHI_OP: begin
				reg_dest = 2'b01;
				alu_src = 1;
				reg_write = 1;
				new_inst = 1;
			end
			`LWD_OP: begin
				reg_dest = 2'b01;
				use_rs = 1;
				alu_src = 1;
				mem_read = 1;
				reg_write = 1;
				reg_src = 2'b01;
				new_inst = 1;
			end
			`SWD_OP: begin
				use_rs = 1;
				alu_src = 1;
				mem_write = 1;
				new_inst = 1;
			end
			`BNE_OP, `BEQ_OP: begin
				use_rs = 1;
				use_rt = 1;
				branch = 1;
				pc_src = 2'b00;
				new_inst = 1;
			end
			`BGZ_OP, `BLZ_OP: begin
				use_rs = 1;
				branch = 1;
				pc_src = 2'b00;
				new_inst = 1;
			end
			`JMP_OP: begin
				pc_src = 2'b01;
				new_inst = 1;
			end
			`JAL_OP: begin
				reg_dest = 2'b10;
				pc_src = 2'b01;
				reg_write = 1;
				reg_src = 2'b10;
				new_inst = 1;
			end
		endcase
	end

	// generate alu control signals
	always @(*) begin
		alu_func_code = 4'd15;
		alu_branch_type = 4'd0;

		case (opcode)
			`ALU_OP: begin
				case(func_code)
					`INST_FUNC_JPR: alu_func_code = `FUNC_ID1; // pc <- rs
					`INST_FUNC_JRL: alu_func_code = `FUNC_ID1; // pc <- rs
					`INST_FUNC_WWD: alu_func_code = `FUNC_ID1; // outputport <- rs
					default: alu_func_code = func_code[3:0];
				endcase
			end
			`ADI_OP: alu_func_code = `FUNC_ADD;
			`ORI_OP: alu_func_code = `FUNC_ORR;
			`LHI_OP: alu_func_code = `FUNC_ID2; // immediate : alu_input_2
			`LWD_OP, `SWD_OP: alu_func_code = `FUNC_ADD;
			`BNE_OP, `BEQ_OP ,`BGZ_OP, `BLZ_OP: begin
				alu_func_code = `FUNC_Bxx;
				alu_branch_type = opcode[1:0]; //branch type for bne = 0, beq = 1, bgz = 2, blz = 3
			end
		endcase
	end

endmodule
