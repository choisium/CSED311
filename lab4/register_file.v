module register_file(read_out1, read_out2, read1, read2, write_reg, write_data, reg_write, clk); 
    input [1:0] read1;
    input [1:0] read2;
    input [1:0] write_reg;
    input [15:0] write_data;
    input reg_write;
    input clk;
    output [15:0] read_out1;
    output [15:0] read_out2;

    reg [15:0] RF [3:0]; // 4 registers each 16 bits long

    initial begin
        RF[0] = 16'b0;
        RF[1] = 16'b0;
        RF[2] = 16'b0;
        RF[3] = 16'b0;
    end

    assign read_out1 = RF[read1];
    assign read_out2 = RF[read2];

    always @(posedge clk) begin
        // write back if reg_write is high
        if (reg_write) RF[write_reg] <= write_data;
        else RF[write_reg] <= RF[write_reg];
    end

    always @(posedge clk) begin
        $display("register file - 0: %0d, 1: %0d, 2: %0d, 3:%0d", RF[0], RF[1], RF[2], RF[3]);
    end

endmodule