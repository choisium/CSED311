`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

`include "datapath.v"
`include "i_cache.v"
`include "d_cache.v"
`include "cache_module.v"

module cpu(clk, reset_n, read_m1, address1, data1, inputReady1, read_m2, write_m2, address2, data2, inputReady2, ackOutput2, num_inst, output_port, is_halted,
	ex_interrupt, dma_interrupt, dma_valid, address, dataLength);

	input clk;
	input reset_n;

	// ports for memory access

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

	// ports for testbench

	output [`WORD_SIZE-1:0] num_inst;
	output [`WORD_SIZE-1:0] output_port;
	output is_halted;

	// ports for DMA
	input ex_interrupt;
	input dma_interrupt;
	output reg dma_valid;
	output reg [`WORD_SIZE-1:0] address;
	output reg [`WORD_SIZE-1:0] dataLength;

	// wires for memory access
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

	wire i_read_m1, d_read_m1;
	wire [`WORD_SIZE-1:0] i_address1, d_address1;
	wire cpu_valid1;
	wire cpu_valid2;

	// wires for DMA
	reg interrupt;

	// assignments for memory access
	assign read_m1 = i_read_m1 | d_read_m1;
	assign address1 = i_read_m1? i_address1: d_address1;
	assign cpu_valid1 = cpu_read_m1;
	assign cpu_valid2 = cpu_read_m2 | cpu_write_m2;

	initial begin
		interrupt <= 0;
		dma_valid <= 0;
	end

	always @(*) begin
		if (ex_interrupt) begin
			dma_valid <= 1;
			interrupt <= 1;
			address <= 16'h17;
			dataLength <= 12;
		end else begin
			dma_valid <= 0;
		end
	end
	
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
		.is_halted(is_halted),
		.interrupt(interrupt)
	);

	instr_cache I_Cache(
		.clk(clk),
		.reset_n(reset_n),
		.cpu_read_m1(cpu_read_m1),
		.cpu_address1(cpu_address1),
		.cpu_data1(cpu_data1),
		.cpu_inputReady1(cpu_inputReady1),
		
		.read_m1(i_read_m1),
		.address1(i_address1),
		.data1(data1),
		.inputReady1(inputReady1),
		.cpu_valid1(cpu_valid1)
	);

	data_cache D_Cache(
		.clk(clk),
		.reset_n(reset_n),

		// memory port 2 related
		.cpu_read_m2(cpu_read_m2),
		.cpu_write_m2(cpu_write_m2),
		.cpu_address2(cpu_address2),
		.cpu_data2(cpu_data2),
		.cpu_inputReady2(cpu_inputReady2),
		.cpu_ackOutput2(cpu_ackOutput2),
		
		.read_m2(read_m2),
		.write_m2(write_m2),
		.address2(address2),
		.data2(data2),
		.inputReady2(inputReady2),
		.ackOutput2(ackOutput2),
		.cpu_valid2(cpu_valid2),

		// memory port 1 related
		.i_read_m1(i_read_m1),
		.read_m1(d_read_m1),
		.address1(d_address1),
		.data1(data1),
		.inputReady1(inputReady1)
	);

endmodule


