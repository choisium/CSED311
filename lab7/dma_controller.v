`timescale 1ns/1ns
`define WORD_SIZE 16

module dma_controller (clk, reset_n, interrupt, valid, address, dataLength, busGrant, busRequest);

input clk;
input reset_n;

input valid;
input [`WORD_SIZE-1:0] address;
input [`WORD_SIZE-1:0] dataLength;

input busGrant;

output reg interrupt;
output reg busRequest;


reg [`WORD_SIZE-1:0] num_clk; // num_clk to count cycles and trigger interrupt at appropriate cycle
reg [`WORD_SIZE-1:0] data [0:`WORD_SIZE-1]; // data to transfer

reg [`WORD_SIZE-1:0] req_address;
reg [`WORD_SIZE-1:0] req_data_length;

always @(posedge clk) begin
	if(!reset_n) begin
		num_clk <= 0;
		interrupt <= 0;
		busRequest <= 0;
	end
	else begin
		num_clk <= num_clk+1;
		// TODO: implement your sequential logic
		if (valid) begin
			req_address <= address;
			req_data_length <= 0;
			busRequest <= 1;
		end
	end
end
endmodule
