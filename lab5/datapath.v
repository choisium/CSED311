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
	reg[`WORD_SIZE-1:0] pc_id, instr_id;

	// ID/EX pipeline register & EX stage wire and reg
	reg[`WORD_SIZE-1:0] pc_ex;

	// EX/MEM pipeline register & EX stage wire and reg
	reg[`WORD_SIZE-1:0] pc_mem;

	// MEM/WB pipeline register & EX stage wire and reg
	reg[`WORD_SIZE-1:0] pc_wb;

	initial begin
		pc = 0;
		pc_id = 0;
		instr_id = 0;
		pc_ex = 0;
		pc_mem = 0;
		pc_wb = 0;
	end


	always @(posedge clk) begin
		if (!reset_n) begin
			pc = 0;
			pc_id = 0;
			instr_id = 0;
			pc_ex = 0;
			pc_mem = 0;
			pc_wb = 0;
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


			$strobe("pc: %h", pc);
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

endmodule

