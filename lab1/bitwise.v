`include "alu_func.v"

module BITWISE #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B, 
	input [3 : 0] FuncCode,
       	output reg [data_width - 1: 0] C);
    

    always @(*) begin
        if (FuncCode === `FUNC_NOT)
            C <= ~A;
        else if (FuncCode === `FUNC_AND)
            C <= A & B;
        else if (FuncCode === `FUNC_OR)
            C <= A | B;
        else if (FuncCode === `FUNC_NAND)
            C <= ~(A & B);
        else if (FuncCode === `FUNC_NOR)
            C <= ~(A | B);
        else if (FuncCode === `FUNC_XOR)
            C <= A ^ B;
        else // FuncCode === `FUNC_XNOR
            C <= ~(A ^ B);
    end

endmodule