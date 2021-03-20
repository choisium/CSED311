module register_file( read_out1, read_out2, read1, read2, write_reg, write_data, reg_write, clk); 
    output [15:0] read_out1;
    output [15:0] read_out2;
    input [1:0] read1;
    input [1:0] read2;
    input [1:0] write_reg;
    input [15:0] write_data;
    input reg_write;
    input clk;

    reg [3:0] RF [15:0]; // 4 registers each 16 bits long

    assign read_out1 = RF[read1];
    assign read_out2 = RF[read2];

    always @(posedge clk) begin
        // write back if reg_write is high
        if (reg_write) RF[write_reg] <= write_data; 
    end
endmodule