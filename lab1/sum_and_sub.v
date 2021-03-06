`include "alu_func.v"

module SUMANDSUB #(parameter data_width = 16) (
	input [data_width - 1 : 0] operand1,
	input [data_width - 1 : 0] operand2,
	input [3 : 0] opCode,
        output reg [data_width - 1: 0] result,
        output reg isOverflow);
    
    wire [data_width - 1: 0] temp;

    assign temp = opCode === `FUNC_ADD ? operand1 + operand2 : operand1 - operand2;

    always @(*) begin
        result <= temp;
        if (opCode === `FUNC_ADD
            ? (operand1[data_width - 1] === operand2[data_width - 1]) && (operand1[data_width - 1] !== temp[data_width -1])
            : (operand1[data_width - 1] !== operand2[data_width - 1]) && (operand1[data_width - 1] !== temp[data_width -1]))
            isOverflow <= 1;
        else
            isOverflow <= 0;
    end

endmodule