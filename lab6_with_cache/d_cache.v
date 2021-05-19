`include "opcodes.v"
`include "cache_def.v"

module data_cache(clk, reset_n, cpu_read_m2, cpu_write_m2, cpu_address2, cpu_data2, cpu_inputReady2, cpu_ackOutput2,
        read_m2, write_m2, address2, data2, inputReady2, ackOutput2, cpu_valid2, valid2);

    input clk;
	input reset_n;

    // I/O between CPU
	input cpu_read_m2;
	input cpu_write_m2;
	input [`WORD_SIZE-1:0] cpu_address2;

	inout [`WORD_SIZE-1:0] cpu_data2;

	output cpu_inputReady2;
    output cpu_ackOutput2;

    // I/O between Memory
	output read_m2;
	output write_m2;
	output [`WORD_SIZE-1:0] address2;

	inout [4*`WORD_SIZE-1:0] data2;

	input inputReady2;
	input ackOutput2;

    input cpu_valid2;
    output valid2;

    // data2
    assign read_m2 = cpu_read_m2;
    assign write_m2 = cpu_write_m2;
    assign address2 = cpu_address2;

    assign data2 = read_m2? 'bz: {4{cpu_data2}};
    assign cpu_data2 = read_m2 && inputReady2 ? data2[`BLOCK_WORD_1] : 'bz;

    assign cpu_inputReady2 = inputReady2;
    assign cpu_ackOutput2 = ackOutput2;

    // assign valid1 = 1;
    assign valid2 = 1;


endmodule