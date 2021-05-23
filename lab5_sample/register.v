`include "opcodes.v" 

module Register (clk, reset_n, reg_read1, reg_read2, reg_dest, reg_write, reg_write_data, reg_read_data1, reg_read_data2);
	input clk, reset_n;
	input [1:0] reg_read1;
	input [1:0] reg_read2;
	input [1:0] reg_dest;
	input reg_write; // signal 1 : write, 0: read
	input [`WORD_SIZE-1:0] reg_write_data;
	

	output [`WORD_SIZE-1:0] reg_read_data1;
	output [`WORD_SIZE-1:0] reg_read_data2;
	
	reg [`WORD_SIZE-1:0] reg_file [`NUM_REGS-1:0];
	
	assign reg_read_data1 = reg_file[reg_read1];
	assign reg_read_data2 = reg_file[reg_read2];

	always @(posedge clk) begin
		if(!reset_n) begin 
			reg_file[0] <= 0;
			reg_file[1] <= 0;
			reg_file[2] <= 0;
			reg_file[3] <= 0;
		end
	end

	always @(negedge clk) begin
		if(reg_write) begin
			reg_file[reg_dest] <= reg_write_data;
		end
	end

endmodule
