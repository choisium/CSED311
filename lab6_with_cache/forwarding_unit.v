`include "opcodes.v"

module forwarding_unit(rs_EX, rt_EX, rd_MEM, reg_write_MEM, rd_WB, reg_write_WB,
                        forward_A, forward_B);
   
    input [1:0] rs_EX, rt_EX, rd_MEM, rd_WB;
    input reg_write_MEM, reg_write_WB;

    output reg [1:0] forward_A, forward_B;

    always @(*) begin
        if((rs_EX == rd_MEM) && reg_write_MEM) begin
            assign forward_A = 2'b01;
        end else if((rs_EX == rd_WB) && reg_write_WB) begin
            assign forward_A = 2'b10;
        end else begin
            assign forward_A = 2'b00;
        end

        if((rt_EX == rd_MEM) && reg_write_MEM) begin
            assign forward_B = 2'b01;
        end else if((rt_EX == rd_WB) && reg_write_WB) begin
            assign forward_B = 2'b10;
        end else begin
            assign forward_B = 2'b00;
        end
    end
endmodule