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
	case (FuncCode)
		`FUNC_ADD, `FUNC_SUB:
			begin
				C <= sumandsub_c;
				OverflowFlag <= sumandsub_overflowflag;
			end
		`FUNC_NOT, `FUNC_AND, `FUNC_OR, `FUNC_NAND,
		`FUNC_NOR, `FUNC_XOR, `FUNC_XNOR:
			begin
				C <= bitwise_c;
				OverflowFlag <= 0;
			end
		`FUNC_LLS, `FUNC_LRS, `FUNC_ALS, `FUNC_ARS:
			begin
				C <= shift_c;
				OverflowFlag <= 0;
			end
		default:
			begin
				C <= other_c;
				OverflowFlag <= 0;
			end
	endcase
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

