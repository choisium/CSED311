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

	assign next_PC = (is_flush | !(PC < 16'hc6))? actual_next_PC: PC + 1;

endmodule


module branch_predictor_always_taken(clk, reset_n, PC, is_flush, is_BJ_type, actual_next_PC, actual_PC, next_PC);

	input clk;
	input reset_n;
	input [`WORD_SIZE-1:0] PC;
	input is_flush;
	input is_BJ_type;
	input [`WORD_SIZE-1:0] actual_next_PC; //computed actual next PC from branch resolve stage
	input [`WORD_SIZE-1:0] actual_PC; // PC from branch resolve stage

	output reg [`WORD_SIZE-1:0] next_PC;

	reg [`IDX_SIZE-1:0] i;
	reg [`TAG_SIZE:0] tagtable [0:(2**`IDX_SIZE)-1];
	reg [`WORD_SIZE-1:0] btb [0:(2**`IDX_SIZE)-1];

	wire [`TAG_SIZE-1:0] tag; wire [`IDX_SIZE-1:0] idx;
	assign tag = PC[`WORD_SIZE-1:`IDX_SIZE];
	assign idx = PC[`IDX_SIZE-1:0];

	always @(*) begin
		if (!reset_n) begin
			for(i = 0; i < `IDX_SIZE; i++) begin
				tagtable[i] = ~0;
				btb[i] = ~0;
			end
		end else begin
			$display("tagtable: %b, btb: %b", tagtable[idx], btb[idx]);
			$display("idx: %b, tag: %b", idx, tag);
			if (is_flush) begin
				$display("prediction failed! update table");
				next_PC = actual_next_PC;
				tagtable[actual_PC[`IDX_SIZE-1:0]] = actual_PC[`WORD_SIZE-1:`IDX_SIZE];
				btb[actual_PC[`IDX_SIZE-1:0]] = actual_next_PC;
			end else if (tagtable[idx] == tag) begin
				$display("tag is same! actual_pc: %h, actual_next_pc: %h", actual_PC, actual_next_PC);
				next_PC = btb[idx];
			end else begin
				$display("tag is not same! actual_pc: %h, actual_next_pc: %h", actual_PC, actual_next_PC);
				next_PC = !(PC < 16'hc6)? PC: PC + 1;
			end
		end
	end

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