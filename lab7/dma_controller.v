`timescale 1ns/1ns
`define WORD_SIZE 16

module dma_controller (clk, reset_n, interrupt, cpu_valid, address, dataLength, busGrant, busRequest,
	ex_valid, offset, read_m2, write_m2, address2, ackOutput2);

input clk;
input reset_n;

// interact to CPU
input cpu_valid;
input [`WORD_SIZE-1:0] address;
input [`WORD_SIZE-1:0] dataLength;

input busGrant;

output reg interrupt;
output reg busRequest;

// interact to external device
output reg [`WORD_SIZE-1:0] offset;
output reg ex_valid;

// interact to Memory
output read_m2, write_m2;
output [`WORD_SIZE-1:0] address2;
output ackOutput2;


// internal reg and wire
reg [`WORD_SIZE-1:0] num_clk; // num_clk to count cycles and trigger interrupt at appropriate cycle
reg [`WORD_SIZE-1:0] data [0:`WORD_SIZE-1]; // data to transfer

reg [`WORD_SIZE-1:0] req_address;
reg [`WORD_SIZE-1:0] req_data_length;

reg access_memory;

// assert proper memory signal and send address through address bus
assign read_m2 = ex_valid? 0: 'bz;
assign write_m2 = ex_valid? 1: 'bz;
assign address2 = ex_valid? req_address + offset * 4: 'bz;

always @(posedge clk) begin
	if(!reset_n) begin
		num_clk <= 0;
		interrupt <= 0;
		busRequest <= 0;
		access_memory <= 0;
		ex_valid <= 0;
	end
	else begin
		num_clk <= num_clk+1;

		// 3. The DMA controller saves the address and dataLength sent from CPU
		// 	  and raises a BusRequest signal
		if (cpu_valid) begin
			req_address <= address;
			req_data_length <= dataLength;
			busRequest <= 1;
		end

		// 6. The DMA controller get BG signal.
		//    Make external device writes 12 words of data at designated memory address
		if (busGrant) begin
			if (!access_memory) begin
				// first cycle after BG signal is asserted
				// send valid signal and offset to external device and remember we started memory access
				ex_valid <= 1;
				offset <= 0;
				access_memory <= 1;
			end else if (ackOutput2) begin
				// get write-done signal from memory
				if (offset < req_data_length / 4 - 1) begin
					// if the data is left, increase offset
					offset <= offset + 1;
				end else begin
					// if all data is writen, make external device stop
					// 8. When the DMA controller finishes its work, it clears the BR signal
					ex_valid <= 0;
					busRequest <= 0;
				end
			end
		end
		
		// 10. The DMA controller raises an interrupt
		if (access_memory && !busGrant) begin
			interrupt <= 1;
			access_memory <= 0;
		end

		// turn off interrupt signal after one cycle
		if (interrupt) begin
			interrupt <= 0;
		end
	end
end
endmodule
