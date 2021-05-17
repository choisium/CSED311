`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

`include "datapath.v"
`include "cache.v"

module cpu(clk, reset_n, read_m1, address1, data1, inputReady1, read_m2, write_m2, address2, data2, inputReady2, ackOutput2, num_inst, output_port, is_halted);

	input clk;
	input reset_n;

	output read_m1;
	output [`WORD_SIZE-1:0] address1;
	output read_m2;
	output write_m2;
	output [`WORD_SIZE-1:0] address2;

	input [4*`WORD_SIZE-1:0] data1;
	inout [4*`WORD_SIZE-1:0] data2;

	input inputReady1;
	input inputReady2;
	input ackOutput2;

	output [`WORD_SIZE-1:0] num_inst;
	output [`WORD_SIZE-1:0] output_port;
	output is_halted;

	wire cpu_read_m1;
	wire [`WORD_SIZE-1:0] cpu_address1;
	wire cpu_read_m2;
	wire cpu_write_m2;
	wire [`WORD_SIZE-1:0] cpu_address2;

	wire [`WORD_SIZE-1:0] cpu_data1;
	wire [`WORD_SIZE-1:0] cpu_data2;

	wire cpu_inputReady1;
	wire cpu_inputReady2;
	wire cpu_ackOutput2;

	//TODO: implement pipelined CPU
	datapath Datapath(
		.clk(clk),
		.reset_n(reset_n),
		.read_m1(cpu_read_m1),
		.address1(cpu_address1),
		.data1(cpu_data1),
		.inputReady1(cpu_inputReady1),
		.read_m2(cpu_read_m2),
		.write_m2(cpu_write_m2),
		.address2(cpu_address2),
		.data2(cpu_data2),
		.inputReady2(cpu_inputReady2),
		.ackOutput2(cpu_ackOutput2),
		.num_inst(num_inst),
		.output_port(output_port),
		.is_halted(is_halted)
	);

	cache Cache(
		.clk(clk),
		.reset_n(reset_n),
		.cpu_read_m1(cpu_read_m1),
		.cpu_address1(cpu_address1),
		.cpu_data1(cpu_data1),
		.cpu_inputReady1(cpu_inputReady1),
		.cpu_read_m2(cpu_read_m2),
		.cpu_write_m2(cpu_write_m2),
		.cpu_address2(cpu_address2),
		.cpu_data2(cpu_data2),
		.cpu_inputReady2(cpu_inputReady2),
		.cpu_ackOutput2(cpu_ackOutput2),
		
		.read_m1(read_m1),
		.address1(address1),
		.data1(data1),
		.inputReady1(inputReady1),
		.read_m2(read_m2),
		.write_m2(write_m2),
		.address2(address2),
		.data2(data2),
		.inputReady2(inputReady2),
		.ackOutput2(ackOutput2)
	);


endmodule


