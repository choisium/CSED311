`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

`include "datapath.v"

module cpu(clk, reset_n, read_m1, address1, data1, inputReady1, read_m2, write_m2, address2, data2, inputReady2, ackOutput2, num_inst, output_port, is_halted);

	input clk;
	input reset_n;

	output read_m1;
	output [`WORD_SIZE-1:0] address1;
	output read_m2;
	output write_m2;
	output [`WORD_SIZE-1:0] address2;

	input [`WORD_SIZE-1:0] data1;
	inout [`WORD_SIZE-1:0] data2;

	input inputReady1;
	input inputReady2;
	input ackOutput2;

	output [`WORD_SIZE-1:0] num_inst;
	output [`WORD_SIZE-1:0] output_port;
	output is_halted;

	//TODO: implement pipelined CPU
	datapath Datapath(
		.clk(clk),
		.reset_n(reset_n),
		.read_m1(read_m1),
		.address1(address1),
		.data1(data1),
		.inputReady1(inputReady1),
		.read_m2(read_m2),
		.write_m2(write_m2),
		.address2(address2),
		.data2(data2),
		.inputReady2(inputReady2),
		.ackOutput2(ackOutput2),
		.num_inst(num_inst),
		.output_port(output_port),
		.is_halted(is_halted)
	);

	reg valid_m1, valid_m2;
	always @(*) begin
		valid_m1 = read_m1;
		valid_m2 = read_m2 | write_m2;
	end

	cache Cache(
		.clk(clk),
		.reset_n(reset_n),
		.cpu_req1({valid_m1, 1'b0, address1, data1}),
		.cpu_res1({inputReady1, data1}),
		.cpu_req2({valid_m2, !read_m1 & write_m2, address2, data2}),
		.cpu_res2({inputReady2, data2}),
		.ackOutput2(ackOutput2)
	);

endmodule


