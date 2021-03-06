`include "alu_func.v"

module BITWISE #(parameter data_width = 16) (
    input [data_width - 1 : 0] operand1,
    input [data_width - 1 : 0] operand2,
    input [3 : 0] opCode,
        output reg [data_width - 1: 0] result);


    always @(*) begin
        case (opCode)
            `FUNC_NOT: result <= ~operand1;
            `FUNC_AND: result <= operand1 & operand2;
            `FUNC_OR: result <= operand1 | operand2;
            `FUNC_NAND: result <= ~(operand1 & operand2);
            `FUNC_NOR: result <= ~(operand1 | operand2);
            `FUNC_XOR: result <= operand1 ^ operand2;
            default: result <= ~(operand1 ^ operand2);  // opCode === `FUNC_XNOR
        endcase
    end

endmodule