`define   NumBits   16

module alu (A, B, func_code, branch_type, C, Overflow_flag, bcond);
   input [`NumBits-1:0] A;
   input [`NumBits-1:0] B;
   input [3:0] func_code;
   input [1:0] branch_type;
   output reg [`NumBits-1:0] C;
   output reg Overflow_flag;
   output reg bcond;

   // You can declare any variables as needed.
   /*
      YOUR VARIABLE DECLARATION...
   */
   wire [15:0] carry1;
   wire [15:0] carry2;
   assign carry1 = (A ^~ B)&(A ^ C);
   assign carry2 = (A ^ B)&(A ^ C);

   
   initial begin
      C = 0;
      bcond = 0;
      Overflow_flag = 0;
   end      

   always@(*) begin

      case (func_code)
      4'b0000:
      begin
         C = A+B;
         Overflow_flag = carry1[15];
      end
      4'b0001:
      begin
         C = A+~B+1;
         Overflow_flag = carry2[15];
      end
      4'b0010:
         C = A;
      4'b0011:
         C = ~A;
      4'b0100:
         C = A&B;
      4'b0101:
         C = A | B;
      4'b0110:
         C = ~(A & B);
      4'b0111:
         C = ~(A | B);
      4'b1000:
         C = A ^ B;
      4'b1001:
         C = A ^~ B;
      4'b1010:
         C = A << 1; 
      4'b1011:
         C = A >> 1;
      4'b1100:
         C = A <<< 1;
      4'b1101:
         C = signed'(A) >>> 1;
      4'b1110:
         C = ~A + 1;
      4'b1111:
         C = 0;
      endcase

      case (branch_type)
        0: begin
          if (A!=B) bcond = 1;
          else bcond = 0;
        end

        1:begin
          if (A==B) bcond = 1;
          else bcond = 0;
        end

        2:begin
          if (signed'(A)>0)bcond = 1;
          else bcond = 0;
        end

        3:begin
          if (signed'(A)<0)bcond = 1;
          else bcond = 0;
        end
      endcase

   
   end
   
endmodule