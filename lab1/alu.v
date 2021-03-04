`include "alu_func.v"
`include "sum_and_sub.v"
`include "bitwise.v"
`include "shift.v"
`include "others.v"


module ALU #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B, 
	input [3 : 0] FuncCode,
       	output reg [data_width - 1: 0] C,
       	output reg OverflowFlag);

wire [data_width - 1: 0] sumandsub_c;
wire sumandsub_overflowflag;
wire [data_width - 1: 0] bitwise_c;
wire [data_width - 1: 0] shift_c;
wire [data_width - 1: 0] other_c;

initial begin
	C = 0;
	OverflowFlag = 0;
end

always @(*) begin
	if (FuncCode >= 4'b0000 && FuncCode <= 4'b0001) begin
		C <= sumandsub_c;
		OverflowFlag <= sumandsub_overflowflag;
	end else if (FuncCode >= 4'b0011 && FuncCode <= 4'b1001) begin
		C <= bitwise_c;
		OverflowFlag <= 0;
	end else if (FuncCode >= 4'b1010 && FuncCode <= 4'b1101) begin
		C <= shift_c;
		OverflowFlag <= 0;
	end else begin
		C <= other_c;
		OverflowFlag <= 0;
	end
end

SUMANDSUB my_sumandsub(
	.A(A),
	.B(B),
	.FuncCode(FuncCode),
	.C(sumandsub_c),
	.OverflowFlag(sumandsub_overflowflag)
);

BITWISE my_bitwise(
	.A(A),
	.B(B),
	.FuncCode(FuncCode),
	.C(bitwise_c)
);

SHIFT my_shift(
	.A(A),
	.FuncCode(FuncCode),
	.C(shift_c)
);

OTHER my_other(
	.A(A),
	.FuncCode(FuncCode),
	.C(other_c)
);

endmodule

