`include "opcodes.v" 

module register_file (read_out1, read_out2, read1, read2, dest, write_data, reg_write, clk, reset_n);

	input clk, reset_n;
	input [1:0] read1;
	input [1:0] read2;
	input [1:0] dest;
	input reg_write;
	input [`WORD_SIZE-1:0] write_data;
	

	output [`WORD_SIZE-1:0] read_out1;
	output [`WORD_SIZE-1:0] read_out2;
	
    reg [`WORD_SIZE-1:0] RF [`NUM_REGS-1:0]; // 4 registers each 16 bits long

    initial begin
        RF[0] = `WORD_SIZE'b0;
        RF[1] = `WORD_SIZE'b0;
        RF[2] = `WORD_SIZE'b0;
        RF[3] = `WORD_SIZE'b0;
    end

    assign read_out1 = RF[read1];
    assign read_out2 = RF[read2];

    always @(posedge clk) begin
		if (!reset_n) begin
			RF[0] = `WORD_SIZE'b0;
			RF[1] = `WORD_SIZE'b0;
			RF[2] = `WORD_SIZE'b0;
			RF[3] = `WORD_SIZE'b0;
		end
		else begin	
			// write back if reg_write is high		
			if (reg_write) RF[dest] <= write_data;
			else RF[dest] <= RF[dest];
			$strobe("RF 0: %h, RF 1: %h, RF 2: %h, RF 3: %h", RF[0], RF[1], RF[2], RF[3]);
		end
    end

endmodule
