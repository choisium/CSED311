`include "opcodes.v"
`include "register_file.v"
`include "alu.v"
`include "control_unit.v" 
`include "branch_predictor.v"
`include "hazard.v"
`include "util.v"

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
	wire[`WORD_SIZE-1:0] pc_nxt;  // predicted_pc

	// IF/ID pipeline register & ID stage wire and reg
	reg[`WORD_SIZE-1:0] pc_id, instr;
	wire halt, use_rs, use_rt, alu_src_id, branch_id, mem_read_id, mem_write_id, reg_write_id, wwd_id, new_inst_id;
	wire[1:0] pc_src_id, reg_dest_id, reg_src_id, alu_branch_type_id;
	wire[3:0] alu_func_code_id;

	// ID/EX pipeline register & EX stage wire and reg
	reg[`WORD_SIZE-1:0] pc_ex;
	wire[`WORD_SIZE-1:0] actual_pc;
	reg alu_src_ex, branch_ex, mem_read_ex, mem_write_ex, reg_write_ex, wwd_ex, new_inst_ex;
	reg[1:0] pc_src_ex, reg_dest_ex, reg_src_ex, alu_branch_type_ex;
	reg[3:0] alu_func_code_ex;

	reg[11:0] target;
	wire flush;

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
		$strobe("address1: %h, data1: %h, instr: %h", address1, data1, instr);
	end

	assign flush = actual_pc != pc_ex? 1: 0;
	always @(*) begin
		$display("pc_nxt: %h, pc: %h, pc_id: %h, pc_ex: %h, pc_mem: %h, pc_wb: %h", pc_nxt, pc, pc_id, pc_ex, pc_mem, pc_wb);
		$display("actual_pc: %h, flush: %b, pc_src_ex: %b", actual_pc, flush, pc_src_ex);
	end

	// update pipeline register
	always @(posedge clk) begin
		$strobe("--- clk posedge --- pc: %h, pc_nxt: %h", pc, pc_nxt);
		if (!reset_n) begin
			pc <= 0;
			pc_id <= 0;
			pc_ex <= 0; pc_src_ex <= 0; target <= 0;
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
			pc_src_ex <= pc_src_id;
			target <= instr[11:0];
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
		.is_flush(flush),
		.is_BJ_type(1'b0),
		.actual_next_PC(`WORD_SIZE'b0),
		.actual_PC(actual_pc),
		.next_PC(pc_nxt)
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

	mux4_1 MUX_pc_src(
		.sel(pc_src_ex),
		.i1(pc_ex),
		.i2({pc_ex[15:12], target}),
		.i3({pc_ex[15:12], target}),
		.i4({pc_ex[15:12], target}),
		.o(actual_pc)
	);


endmodule

