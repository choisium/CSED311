`include "opcodes.v"

`define	NumBits	16

module alu (alu_input_1, alu_input_2, alu_func_code, alu_output, zero);
	input [`NumBits-1:0] alu_input_1;
	input [`NumBits-1:0] alu_input_2;
	input [3:0] alu_func_code;
	output reg [`NumBits-1:0] alu_output;
	output zero;

	assign zero = (alu_output == 0);

	always @(*) begin
		case(alu_func_code)
			`FUNC_ADD: alu_output = alu_input_1 + alu_input_2;
			`FUNC_SUB: alu_output = alu_input_1 - alu_input_2;
			`FUNC_AND: alu_output = alu_input_1 & alu_input_2;
			`FUNC_ORR: alu_output = alu_input_1 | alu_input_2;
			`FUNC_NOT: alu_output = ~alu_input_1;
			`FUNC_TCP: alu_output = ~alu_input_1 + 1;
			`FUNC_SHL: alu_output = {alu_input_1[14:0], 1'b0};
			`FUNC_SHR: alu_output = {alu_input_1[15], alu_input_1[15:1]} ;
			default: alu_output = 0; // not happen
		endcase
	end
endmodule