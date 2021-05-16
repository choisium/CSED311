`include "opcodes.v" 

`define NumBits 16

module alu (A, B, func_code, branch_type, alu_out, overflow_flag, bcond);

	input [`WORD_SIZE-1:0] A;
	input [`WORD_SIZE-1:0] B;
	input [3:0] func_code;
	input [1:0] branch_type; 

	output reg [`WORD_SIZE-1:0] alu_out;
	output reg overflow_flag; 
	output reg bcond;

// localparam for branch types
   localparam BNE = 2'd0;
   localparam BEQ = 2'd1;
   localparam BGZ = 2'd2;
   localparam BLZ = 2'd3;

   always @(*) begin

      // reset output
      alu_out = 0;
      overflow_flag = 0;

      case(func_code)
         `FUNC_ADD: begin
            alu_out = A + B;
            // NOTE : From Soomin's lab1 overflow detection
            if((A[`NumBits - 1] === B[`NumBits - 1])
            && (A[`NumBits - 1] !== alu_out[`NumBits -1]))
               overflow_flag = 1;
            else
               overflow_flag = 0;
         end
         `FUNC_SUB: begin
            alu_out = A - B;
            if((A[`NumBits - 1] !== B[`NumBits - 1])
            && (A[`NumBits - 1] !== alu_out[`NumBits -1]))
               overflow_flag = 1;
            else
               overflow_flag = 0;
         end
         `FUNC_AND: alu_out = A & B;
         `FUNC_ORR: alu_out = A | B;
         `FUNC_NOT: alu_out = ~A;
         `FUNC_TCP: alu_out = ~A + 1;
         `FUNC_SHL: alu_out = {A[14:0], 1'b0};
         `FUNC_SHR: alu_out = {A[15], A[15:1]};
         `FUNC_ID1: alu_out = A;
         `FUNC_ID2: alu_out = B;
         `FUNC_Bxx: begin
            case(branch_type)
               BNE: bcond = (A != B)? 1 : 0; // 1 if not equal
               BEQ: bcond = (A == B)? 1 : 0; // 1 if equal
               BGZ: bcond = (A[15] == 0 && A != 0)? 1 : 0; //  1 if A > 0
               BLZ: bcond = A[15]; //  1 if A < 0
            endcase
            alu_out = bcond;
         end

         default: begin // not happen
            alu_out = 0;
            overflow_flag = 0;
            bcond = 0;
         end
      endcase
   end

endmodule