`include "opcodes.v"
`include "register_file.v"
`include "alu.v"
`include "control_unit.v" 
`include "branch_predictor.v"
`include "hazard.v"

module datapath(clk, reset_n, read_m1, address1, data1, read_m2, write_m2, address2, data2, num_inst, output_port, is_halted);

	input clk;
	input reset_n;

	output read_m1;
	output [`WORD_SIZE-1:0] address1;
	output read_m2;
	output write_m2;
	output [`WORD_SIZE-1:0] address2;

	input [`WORD_SIZE-1:0] data1;
	inout [`WORD_SIZE-1:0] data2;

	output reg [`WORD_SIZE-1:0] num_inst;
	output reg [`WORD_SIZE-1:0] output_port;
	output is_halted;

	//TODO: implement datapath of pipelined CPU

	// PC
	reg[`WORD_SIZE-1:0] pc;
	wire[`WORD_SIZE-1:0] predicted_pc, pc_nxt;  // predicted_pc

	assign pc_nxt = predicted_pc;  // temporary pc selection!

	// IF/ID pipeline register & ID stage wire and reg
	reg[`WORD_SIZE-1:0] pc_id, instr;
	wire halt, use_rs, use_rt, alu_src_id, branch_id, mem_read_id, mem_write_id, reg_write_id, wwd_id, new_inst_id;
	wire[1:0] pc_src_id, reg_dest_id, reg_src_id, alu_branch_type_id;
	wire[3:0] alu_func_code_id;

	// ID/EX pipeline register & EX stage wire and reg
	reg[`WORD_SIZE-1:0] pc_ex;

	// EX/MEM pipeline register & EX stage wire and reg
	reg[`WORD_SIZE-1:0] pc_mem;

	// MEM/WB pipeline register & EX stage wire and reg
	reg[`WORD_SIZE-1:0] pc_wb;

	initial begin
		pc = 0;
		pc_id = 0;
		instr = 0;
		pc_ex = 0;
		pc_mem = 0;
		pc_wb = 0;

		instr <= 0;
	end

	assign read_m1 = 1;
	assign address1 = pc;
	assign write_m2 = 0;
	assign read_m2 = 0;
	assign address2 = 0;

	// get memory data
	always @(posedge clk) begin
		if (!reset_n) begin
			instr <= 0;
		end
		else begin
			instr <= data1;
		end
	end

	always @(*) begin
		$strobe("address1: %h, data1: %h, pc: %h, pc_id: %h, instr: %h", address1, data1, pc, pc_id, instr);
	end

	// update pipeline register
	always @(posedge clk) begin
		if (!reset_n) begin
			pc <= 0;
			pc_id <= 0;
			pc_ex <= 0;
			pc_mem <= 0;
			pc_wb <= 0;
		end
		else begin
			// update pc
			pc <= pc_nxt;
			// update IF/ID pipeline register
			pc_id <= pc;
			// update ID/EX pipeline register
			pc_ex <= pc_id;
			// update EX/MEM pipeline register
			pc_mem <= pc_ex;
			// update MEM/WB pipeline register
			pc_wb <= pc_mem;
		end
	end

	branch_predictor BranchPredictor(
		.clk(clk),
		.reset_n(reset_n),
		.PC(pc),
		.is_flush(1'b0),
		.is_BJ_type(1'b0),
		.actual_next_PC(`WORD_SIZE'b0),
		.actual_PC(`WORD_SIZE'b0),
		.next_PC(predicted_pc)
	);

	control_unit ControlUnit(
		.opcode(instr[15:12]),
		.func_code(instr[5:0]),
		.clk(clk),
		.reset_n(reset_n),
		.halt(halt),
		.wwd(wwd_id),
		.new_inst(new_inst_id),
		.use_rs(use_rs),
		.use_rt(use_rt),
		.alu_src(alu_src_id),
		.branch(branch_id),
		.mem_read(mem_read_id),
		.mem_write(mem_write_id),
		.reg_write(reg_write_id),
		.pc_src(pc_src_id),
		.reg_dest(reg_dest_id),
		.reg_src(reg_src_id),
		.alu_branch_type(alu_branch_type_id),
		.alu_func_code(alu_func_code_id)
	);

endmodule

