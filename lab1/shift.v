`include "alu_func.v"

module SHIFT #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [3 : 0] FuncCode,
       	output reg [data_width - 1: 0] C);

    wire [data_width - 1: 0] sign = A[data_width - 1] << data_width - 1;

    always @(*) begin
        case (FuncCode)
            `FUNC_LLS: C <= A << 1;
            `FUNC_LRS: C <= A >> 1;
            `FUNC_ALS: C <= A <<< 1;
            default: C <= (A >> 1) + sign;  // FuncCode === `FUNC_ARS
        endcase
    end

endmodule