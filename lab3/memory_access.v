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

	reg [`WORD_SIZE-1:0] temp_data;

	assign data = temp_data;

	// NOTE: This is for test! Before submit, delete this code!
	always @(*) begin
		$display("---MEMORY ACCESS DISPLAY---");
		$display("readM: %d, inputReady: %d, writeM: %d, ackOutput: %d, address: %d, data: %h, temp_data: %d", readM, inputReady, writeM, ackOutput, address, data, temp_data);
	end
	// NOTE END

	// update writeM to 0 after writing is done
	always @(ackOutput) begin
		if (ackOutput == 1) begin
			writeM = 0;
		end
		else begin
			writeM = writeM;
		end
	end

	// update readM to 0 after reading is done
	always @(inputReady) begin
		if (inputReady == 1) begin
			readM = 0;
		end
		else begin
			readM = readM;
		end
	end

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
		$display("---MEMORY ACCESS POSEDGE---");
		$display("pc value: %d, pc nxt value: %d", pc, pc_nxt);
		$display("readM: %d, writeM: %d, address: %d", readM, writeM, address);
		// NOTE END
	end

	// read or write memory
	always @(negedge clk) begin
		readM <= mem_read;
		writeM <= mem_write;
		address <= mem_address;
		temp_data <= mem_write? mem_data: `WORD_SIZE'bz;;

		// NOTE: This is for test! Before submit, delete this code!
		$display("---MEMORY ACCESS NEGEDGE---");
		$display("mem_read: %d, mem_write: %d, mem_address: %d, mem_data", mem_read, mem_write, mem_address, mem_data);
		$display("readM: %d, writeM: %d, address: %d, data: %d, temp_data: %d", readM, writeM, address, data, temp_data);
		// NOTE END
	end

endmodule