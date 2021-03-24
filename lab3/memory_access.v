`include "opcodes.v" 	   

module memory_access (pc, pc_nxt, mem_read, mem_write, mem_address, mem_data,
					  readM, writeM, address, data, ackOutput, inputReady, pc_update, 
					  instrFetch, memAccess,
					  reset_n, clk);
	output reg [`WORD_SIZE-1: 0] pc, pc_nxt;
	output reg readM;
	output reg writeM;
	output reg [`WORD_SIZE-1:0] address;
	output reg instrFetch, memAccess;
	inout [`WORD_SIZE-1:0] data;
	input mem_read;
	input mem_write;
	input [`WORD_SIZE-1:0] mem_address;
	input [`WORD_SIZE-1:0] mem_data;
	input ackOutput;
	input inputReady;
	input [`WORD_SIZE-1: 0] pc_update;
	input reset_n;
	input clk;

	initial begin
		pc = 0;
		pc_nxt = 0;
		instrFetch = 0;
		memAccess = 0;
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
		if (!reset_n) begin
			// reset all states.
			pc <= 0;
			pc_nxt <= 0;
		end
		else begin
			pc_nxt <= pc_update + 1;
			pc <= pc_update;
		end
	end

	// instruction fetch
	always @(posedge clk) begin
		readM <= 1;
		writeM <= 0;
		address <= pc_update;
		temp_data <= `WORD_SIZE'bz;
		
		instrFetch <= 1;
		memAccess <= 0;
		// NOTE: This is for test! Before submit, delete this code!
		$strobe("---MEMORY ACCESS POSEDGE---");
		$strobe("pc value: %d, pc nxt value: %d, pc update value: %d", pc, pc_nxt, pc_update);
		$strobe("readM: %d, writeM: %d, address: %d", readM, writeM, address);
		$strobe("instrFetch: %d, memAccess: %d", instrFetch, memAccess);
		// NOTE END
	end

	// read or write memory
	always @(negedge clk) begin
		readM <= mem_read;
		writeM <= mem_write;
		address <= mem_address;
		temp_data <= mem_write? mem_data: `WORD_SIZE'bz;

		instrFetch <= 0;
		memAccess <= 1;
		// NOTE: This is for test! Before submit, delete this code!
		$strobe("---MEMORY ACCESS NEGEDGE---");
		$strobe("mem_read: %d, mem_write: %d, mem_address: %d, mem_data", mem_read, mem_write, mem_address, mem_data);
		$strobe("readM: %d, writeM: %d, address: %d, data: %d, temp_data: %d", readM, writeM, address, data, temp_data);
		$strobe("instrFetch: %d, memAccess: %d", instrFetch, memAccess);
		// NOTE END
	end

endmodule