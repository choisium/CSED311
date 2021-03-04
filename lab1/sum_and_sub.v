`include "alu_func.v"

module SUMANDSUB #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B,
	input [3 : 0] FuncCode,
       	output reg [data_width - 1: 0] C,
       	output reg OverflowFlag);
    
    wire [data_width - 1: 0] result;

    assign result = FuncCode === `FUNC_ADD ? A + B : A - B;

    always @(*) begin
        C <= result;
        if (FuncCode === `FUNC_ADD ? (A[data_width - 1] === B[data_width - 1]) && (A[data_width - 1] !== result[data_width -1]) : (A[data_width - 1] !== B[data_width - 1]) && (A[data_width - 1] !== result[data_width -1]))
            OverflowFlag <= 1;
        else
            OverflowFlag <= 0;
    end

endmodule