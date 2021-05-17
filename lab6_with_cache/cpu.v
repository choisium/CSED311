`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

`include "datapath.v"
`include "cache_def.v"

module cpu(clk, reset_n,
		//read_m2, write_m2, address2, data2, inputReady2, ackOutput2, 
		num_inst, output_port, is_halted, 
		mem_req1, mem_req2, mem_data1, mem_data2);

	input clk;
	input reset_n;

	wire read_m1;
	wire [`WORD_SIZE-1:0] address1;
	wire read_m2;
	wire write_m2;
	wire [`WORD_SIZE-1:0] address2;

	wire [`WORD_SIZE-1:0] data1;
	wire [`WORD_SIZE-1:0] data2;

	wire inputReady1;
	wire inputReady2;
	wire ackOutput1;
	wire ackOutput2;

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

	output [`MEM_REQ_SIZE-1:0] mem_req1;
	output [`MEM_REQ_SIZE-1:0] mem_req2;
	input [`MEM_DATA_SIZE-1:0] mem_data1;
	input [`MEM_DATA_SIZE-1:0] mem_data2;

	reg valid_m1, valid_m2;


	always @(*) begin
		valid_m1 = read_m1;
		valid_m2 = read_m2 | write_m2;
	end

	cache Cache(
		.clk(clk),
		.reset_n(reset_n),
		.cpu_req1({valid_m1, 1'b0, address1, data1}),
		.cpu_res1({inputReady1, ackOutput1, data1}),
		.cpu_req2({valid_m2, !read_m2 & write_m2, address2, data2}),
		.cpu_res2({inputReady2, ackOutput2, data2}),
		.mem_req1(mem_req1),
		.mem_req2(mem_req2),
		.mem_data1(mem_data1),
		.mem_data2(mem_data2)
	);

endmodule
