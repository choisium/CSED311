`include "alu_func.v"

module BITWISE #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B, 
	input [3 : 0] FuncCode,
       	output reg [data_width - 1: 0] C);
    

    always @(*) begin
        case (FuncCode)
            `FUNC_NOT: C <= ~A;
            `FUNC_AND: C <= A & B;
            `FUNC_OR: C <= A | B;
            `FUNC_NAND: C <= ~(A & B);
            `FUNC_NOR: C <= ~(A | B);
            `FUNC_XOR: C <= A ^ B;
            default: C <= ~(A ^ B);  // FuncCode === `FUNC_XNOR
        endcase
    end

endmodule