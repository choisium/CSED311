`include "alu_func.v"

module OTHER #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [3 : 0] FuncCode,
       	output reg [data_width - 1: 0] C);

    always @(*) begin
        case(FuncCode)
            `FUNC_ID: C <= A;
            `FUNC_TCP: C <= ~A + 1;
            default: C <= 0;  // FuncCode === `FUNC_ZERO
        endcase
    end

endmodule