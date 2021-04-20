`include "opcodes.v" 	   

module control_unit (opcode, alu_src, reg_write, mem_read, mem_to_reg, mem_write, jal, branch);
input [`WORD_SIZE:0] opcode;
output reg alu_src;
output reg reg_write;
output reg mem_read;
output reg mem_to_reg;
output reg mem_write;
output reg jal;
output reg branch;

wire rtype;
wire itype;
wire lw;
wire sw;
wire br;
wire jp;

assign rtype = opcode[0] & opcode[1] & opcode[2] & opcode[3]; // 15
assign itype = ~opcode[3] | (~opcode[0] & ~opcode[1] & ~opcode[2] & opcode[3]); // 0~8
assign lw = ~opcode[3] &  opcode[2] &  opcode[1] &  opcode[0]; // 7
assign sw =  opcode[3] & ~opcode[0] & ~opcode[1] & ~opcode[2]; // 8
assign br = ~opcode[3] & ~opcode[2]; //0 ~3
assign jp =  opcode[3] & ~opcode[2] & (opcode[1] ^ opcode[0]); // 9, 10

initial begin
    jal <= 0;
    branch <= 0;
    mem_read <= 0;
    mem_write <= 0;
    alu_src <= 0;
    reg_write <= 0;
    mem_to_reg <= 0;
end

//Combinational logic for output
always @(*) begin
    jal = jp;
    branch = br;
    mem_write = sw;
    alu_src = itype;
    reg_write = (jp &(opcode[3] & ~opcode[2] &opcode[1] & ~opcode[0] )) | (itype & ~sw & ~br) | rtype;
    mem_to_reg = lw;
    mem_read = lw;
end
endmodule