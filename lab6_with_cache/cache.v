`include "opcodes.v"
`include "cache_def.v"

module cache(clk, reset_n, cpu_read_m1, cpu_address1, cpu_data1, cpu_inputReady1, 
        cpu_read_m2, cpu_write_m2, cpu_address2, cpu_data2, cpu_inputReady2, cpu_ackOutput2,
        read_m1, address1, data1, inputReady1, read_m2, write_m2, address2, data2, inputReady2, ackOutput2);

	input clk;
	input reset_n;

    // I/O between CPU
    input cpu_read_m1;
	input [`WORD_SIZE-1:0] cpu_address1;
	input cpu_read_m2;
	input cpu_write_m2;
	input [`WORD_SIZE-1:0] cpu_address2;

	output [`WORD_SIZE-1:0] cpu_data1;
	inout [`WORD_SIZE-1:0] cpu_data2;
    // reg [`WORD_SIZE-1:0] cpu_data2;

	output cpu_inputReady1;
	output cpu_inputReady2;
    output cpu_ackOutput2;

    // I/O between Memory
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

    // Assign 
    assign read_m1 = cpu_read_m1;
    assign address1 = cpu_address1;
    assign read_m2 = cpu_read_m2;
    assign write_m2 = cpu_write_m2;
    assign address2 = cpu_address2;

    assign cpu_data1 = data1[`BLOCK_WORD_1];

    assign data2 = read_m2? 'bz: {4{cpu_data2}};
    assign cpu_data2 = read_m2 && inputReady2 ? data2[`BLOCK_WORD_1] : 'bz;

    assign cpu_inputReady1 = inputReady1;
    assign cpu_inputReady2 = inputReady2;
    assign cpu_ackOutput2 = ackOutput2;

endmodule
