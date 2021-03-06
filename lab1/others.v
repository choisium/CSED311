`include "alu_func.v"

module OTHER #(parameter data_width = 16) (
    input [data_width - 1 : 0] operand,
    input [3 : 0] opCode,
        output reg [data_width - 1: 0] result);

    always @(*) begin
        case(opCode)
            `FUNC_ID: result <= operand;
            `FUNC_TCP: result <= ~operand + 1;
            default: result <= 0;  // opCode === `FUNC_ZERO
        endcase
    end

endmodule