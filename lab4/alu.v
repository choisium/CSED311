`include "opcodes.v"

`define NumBits 16

module alu (A, B, func_code, branch_type, C, overflow_flag, bcond);
   input [`NumBits-1:0] A; //input data A
   input [`NumBits-1:0] B; //input data B
   input [3:0] func_code; //function code for the operation
   input [1:0] branch_type; //branch type for bne, beq, bgz, blz
   output reg [`NumBits-1:0] C; //output data C
   output reg overflow_flag; 
   output reg bcond; //1 if branch condition met, else 0

   // localparam for branch types
   localparam BNE = 2d'0;
   localparam BEQ = 2d'1;
   localparam BGZ = 2d'2;
   localparam BLZ = 2d'3;

   always @(*) begin
      
      // reset output
      C = 0;
      overflow = 0;
   
      case(func_code)
         `FUNC_ADD: begin 
            C = A + B; 
            // NOTE : From Soomin's lab1 overflow detection
            if((A[`NumBits - 1] === B[`NumBits - 1]) 
            && (A[`NumBits - 1] !== C[`NumBits -1]))
               overflow_flag = 1;
            else
               overflow_flag = 0;
         end
         `FUNC_SUB: begin 
            C = A - B; 
            if((A[`NumBits - 1] !== B[`NumBits - 1]) 
            && (A[`NumBits - 1] !== C[`NumBits -1]))
               overflow_flag = 1;
            else
               overflow_flag = 0;
         end
         `FUNC_AND: C = A & B;
         `FUNC_ORR: C = A | B;
         `FUNC_NOT: C = ~A;
         `FUNC_TCP: C = ~A + 1;
         `FUNC_SHL: C = {A[14:0], 1'b0};
         `FUNC_SHR: C = {A[15], A[15:1]};
         `FUNC_ID1: C = A;
         `FUNC_ID2: C = B;
         `FUNC_Bxx: begin
            case(branch_type) begin
               BNE: bcond = (A != B)? 1 : 0; // 1 if not equal
               BEQ: bcond = (A == B)? 1 : 0; // 1 if equal
               BGZ: bcond = (A > 0)? 1 : 0; //  1 if A > 0
               BLZ: bcond = (A < 0)? 1 : 0; //  1 if A < 0
            end
            C = bcond
         end

         default: begin // not happen 
            C = 0; 
            overflow_flag = 0;
            bcond = 0;
         end
      endcase
   end
endmodule