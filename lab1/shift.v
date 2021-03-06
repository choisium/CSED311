`include "alu_func.v"

module SHIFT #(parameter data_width = 16) (
    input [data_width - 1 : 0] operand,
    input [3 : 0] opCode,
        output reg [data_width - 1: 0] result);

    wire [data_width - 1: 0] sign = operand[data_width - 1] << data_width - 1;

    always @(*) begin
        case (opCode)
            `FUNC_LLS: result <= operand << 1;
            `FUNC_LRS: result <= operand >> 1;
            `FUNC_ALS: result <= operand <<< 1;
            default: result <= (operand >> 1) + sign;  // opCode === `FUNC_ARS
        endcase
    end

endmodule
