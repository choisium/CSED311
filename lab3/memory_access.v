`include "opcodes.v" 	   

module memory_access (pc, pc_nxt, mem_read, mem_write, mem_address, mem_data,
					  readM, writeM, address, data, ackOutput, inputReady, reset_n, clk);
	output reg [`WORD_SIZE-1: 0] pc, pc_nxt;
	output reg readM;
	output reg writeM;
	output reg [`WORD_SIZE-1:0] address;
	inout [`WORD_SIZE-1:0] data;
	input mem_read;
	input mem_write;
	input [`WORD_SIZE-1:0] mem_address;
	input [`WORD_SIZE-1:0] mem_data;
	input ackOutput;
	input inputReady;
	input reset_n;
	input clk;

	initial begin
		pc = 0;
		pc_nxt = 0;
	end

	reg temp_data;

	assign data = (readM || inputReady)? `WORD_SIZE'bz: temp_data;

	// update pc
	always @(posedge clk) begin
		pc_nxt <= pc_nxt + 1;
	end

	// instruction fetch
	always @(posedge clk) begin
		pc <= pc_nxt;
		readM <= 1;
		writeM <= 0;
		address <= pc;
		temp_data <= `WORD_SIZE'bz;
		// NOTE: This is for test! Before submit, delete this code!
		$strobe("---MEMORY ACCESS---");
		$strobe("pc value: %d, pc nxt value: %d", pc, pc_nxt);
		$strobe("readM: %d, writeM: %d, address: %d", readM, writeM, address);
		// NOTE END
	end

	// read or write memory
	always @(negedge clk) begin
		readM <= mem_read;
		writeM <= mem_write;
		address <= mem_address;
		temp_data <= mem_read ? `WORD_SIZE'bz : mem_data;
	end

endmodule