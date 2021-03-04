`include "alu_func.v"

module OTHER #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [3 : 0] FuncCode,
       	output reg [data_width - 1: 0] C);

    always @(*) begin
        if (FuncCode === `FUNC_ID)
            C <= A;
        else if (FuncCode === `FUNC_TCP)
            C <= ~A + 1;
        else // FuncCode === `FUNC_ZERO
            C <= 0;
    end

endmodule