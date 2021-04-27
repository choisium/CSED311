`include "opcodes.v" 

module branch_predictor_always_not_taken(clk, reset_n, PC, is_flush, is_BJ_type, actual_next_PC, actual_PC, next_PC);

	input clk;
	input reset_n;
	input [`WORD_SIZE-1:0] PC;
	input is_flush;
	input is_BJ_type;
	input [`WORD_SIZE-1:0] actual_next_PC; //computed actual next PC from branch resolve stage
	input [`WORD_SIZE-1:0] actual_PC; // PC from branch resolve stage

	output [`WORD_SIZE-1:0] next_PC;

	assign next_PC = (is_flush | !(PC < 16'hc6))? actual_PC: PC + 1;

endmodule


module branch_predictor_always_taken(clk, reset_n, PC, is_flush, is_BJ_type, actual_next_PC, actual_PC, next_PC);

	input clk;
	input reset_n;
	input [`WORD_SIZE-1:0] PC;
	input is_flush;
	input is_BJ_type;
	input [`WORD_SIZE-1:0] actual_next_PC; //computed actual next PC from branch resolve stage
	input [`WORD_SIZE-1:0] actual_PC; // PC from branch resolve stage

	output [`WORD_SIZE-1:0] next_PC;

	assign next_PC = (is_flush | !(PC < 16'hc6))? actual_PC: PC + 1;
	//TODO: implement branch predictor

endmodule


module branch_predictor_global_predictor(clk, reset_n, PC, is_flush, is_BJ_type, actual_next_PC, actual_PC, next_PC);

	input clk;
	input reset_n;
	input [`WORD_SIZE-1:0] PC;
	input is_flush;
	input is_BJ_type;
	input [`WORD_SIZE-1:0] actual_next_PC; //computed actual next PC from branch resolve stage
	input [`WORD_SIZE-1:0] actual_PC; // PC from branch resolve stage

	output [`WORD_SIZE-1:0] next_PC;

	assign next_PC = (is_flush | !(PC < 16'hc6))? actual_PC: PC + 1;
	//TODO: implement branch predictor

endmodule