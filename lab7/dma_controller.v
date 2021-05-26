`timescale 1ns/1ns
`define WORD_SIZE 16

module dma_controller (clk, reset_n, interrupt, cpu_valid, address, dataLength, busGrant, busRequest,
	ex_valid, offset, write_m2, address2, ackOutput2);

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
output write_m2;
output [`WORD_SIZE-1:0] address2;
output ackOutput2;


// internal reg and wire
reg [`WORD_SIZE-1:0] num_clk; // num_clk to count cycles and trigger interrupt at appropriate cycle
reg [`WORD_SIZE-1:0] data [0:`WORD_SIZE-1]; // data to transfer

reg [`WORD_SIZE-1:0] req_address;
reg [`WORD_SIZE-1:0] req_data_length;

reg access_memory;

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
		// TODO: implement your sequential logic
		if (cpu_valid) begin
			req_address <= address;
			req_data_length <= dataLength;
			busRequest <= 1;
		end

		if (busGrant && !access_memory) begin
			ex_valid <= 1;
			offset <= 0;
			access_memory <= 1;
		end
		
		if (busGrant && access_memory && ackOutput2) begin
			if (offset < req_data_length / 4 - 1) begin
				offset <= offset + 1;
			end else begin
				ex_valid <= 0;
				busRequest <= 0;
			end
		end

		if (access_memory && !busGrant) begin
			interrupt <= 1;
			access_memory <= 0;
		end

		if (interrupt) begin
			interrupt <= 0;
		end
	end
end
endmodule
