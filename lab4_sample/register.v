`include "opcodes.v" 	   

module register (rs, rt, rd, write_data, reg_write, clk, read_data1, read_data2);

  input [1:0] rs;
  input [1:0] rt;
  input [1:0] rd;

  input [15:0] write_data;
  input [1:0] reg_write;
  input clk;
  
  output reg [15:0] read_data1;
  output reg [15:0] read_data2;

  reg [15:0] register [0:`NUM_REGS];
  

  integer i;

  initial begin
		for (i=0; i<`NUM_REGS; i = i+1) begin
			register[i] = 0;
		end
	end

  // write Block
  always @(posedge clk) begin
    read_data1 <= register[rs];
    read_data2 <= register[rt];

    if (reg_write == 1) begin
      register[rs] <= write_data;
    end
    else if (reg_write == 2) begin
      register[rt] <= write_data;
    end
    else if (reg_write == 3) begin
      register[rd] <= write_data;
    end
  end

endmodule


module ir_register(mem_data, ir_write, clk, inst);
  input [15:0] mem_data;
  input ir_write;
  input clk;
  output wire [15:0] inst;

  reg [`WORD_SIZE-1:0] ir;

  assign inst = ir;

  always @(posedge clk) begin
    if (ir_write == 1)
      ir <= mem_data;
  end

endmodule

module mem_register(mem_data, clk, mem);
  input [15:0] mem_data;
  input clk;
  output wire [15:0] mem;
  reg [`WORD_SIZE-1:0] m;

  assign mem = m;

  always @(posedge clk) begin
    m <= mem_data;
  end

endmodule

module A_register(read_data1, clk, A);
  input [15:0] read_data1;
  input clk;
  output [15:0] A;

  reg [`WORD_SIZE-1:0] a;
  assign A = a;

  always @(posedge clk) begin
    a <= read_data1;
  end

endmodule

module B_register(read_data2, clk, B);
  input [15:0] read_data2;
  input clk;
  output [15:0] B;
  

  reg [`WORD_SIZE-1:0] b;
  assign B = b;
  always @(posedge clk) begin
    b <= read_data2;
  end

endmodule


module alu_out_register(alu_result, clk, O);
  input [15:0] alu_result;
  input clk;
  output [15:0] O;
  

  reg [`WORD_SIZE-1:0] o;
  assign O = o;
  always @(posedge clk) begin
    o <= alu_result;
  end

endmodule
