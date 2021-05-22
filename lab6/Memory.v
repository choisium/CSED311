`timescale 1ns/1ns
`include "opcodes.v"
`define PERIOD1 100
`define MEMORY_SIZE 256	//	size of memory is 2^8 words (reduced size)
`define WORD_SIZE 16	//	instead of 2^16 words to reduce memory
			//	requirements in the Active-HDL simulator 

module Memory(clk, reset_n, read_m1, address1, data1, inputReady1, read_m2, write_m2, address2, data2, inputReady2, ackOutput2);

	input clk;
	wire clk;
	input reset_n;
	wire reset_n;
	
	input read_m1;
	wire read_m1;
	input [`WORD_SIZE-1:0] address1;
	wire [`WORD_SIZE-1:0] address1;
	output [`WORD_SIZE-1:0] data1;
	reg [`WORD_SIZE-1:0] data1;
	output inputReady1;
	reg inputReady1;
	
	input read_m2;
	wire read_m2;
	input write_m2;
	wire write_m2;
	input [`WORD_SIZE-1:0] address2;
	wire [`WORD_SIZE-1:0] address2;
	inout [`WORD_SIZE-1:0] data2;
	wire [`WORD_SIZE-1:0] data2;
	output inputReady2;
	reg inputReady2;
	output ackOutput2;
	reg ackOutput2;
	
	reg [`WORD_SIZE-1:0] memory [0:`MEMORY_SIZE-1];
	reg [`WORD_SIZE-1:0] output_data2;

	// count1 for instruction latency
	// count2 for data latency
	reg [2:0] count1, count2;
	reg [`WORD_SIZE-1:0] requested_address1, requested_address2, requested_data;
	
	assign data2 = read_m2 ? output_data2 : `WORD_SIZE'bz;
	
	always@(posedge clk)
		if(!reset_n)
			begin
				count1 <= 0; count2 <= 0;
				requested_address1 <= 0; requested_address2 <= 0; requested_data <= 0;
				output_data2 <= 0;
				inputReady1 <= 0; inputReady2 <= 0; ackOutput2 <= 0;

				memory[16'h0] <= 16'h9023; // JMP ENTRY
				memory[16'h1] <= 16'h1;
				memory[16'h2] <= 16'hffff;
				memory[16'h3] <= 16'h0;
				memory[16'h4] <= 16'h0;
				memory[16'h5] <= 16'h0;
				memory[16'h6] <= 16'h0;
				memory[16'h7] <= 16'h0;
				memory[16'h8] <= 16'h0;
				memory[16'h9] <= 16'h0;
				memory[16'ha] <= 16'h0;
				memory[16'hb] <= 16'h0;
				memory[16'hc] <= 16'h0;
				memory[16'hd] <= 16'h0;
				memory[16'he] <= 16'h0;
				memory[16'hf] <= 16'h0;
				memory[16'h10] <= 16'h0;
				memory[16'h11] <= 16'h0;
				memory[16'h12] <= 16'h0;
				memory[16'h13] <= 16'h0;
				memory[16'h14] <= 16'h0;
				memory[16'h15] <= 16'h0;
				memory[16'h16] <= 16'h0;
				memory[16'h17] <= 16'h0;
				memory[16'h18] <= 16'h0;
				memory[16'h19] <= 16'h0;
				memory[16'h1a] <= 16'h0;
				memory[16'h1b] <= 16'h0;
				memory[16'h1c] <= 16'h0;
				memory[16'h1d] <= 16'h0;
				memory[16'h1e] <= 16'h0;
				memory[16'h1f] <= 16'h0;
				memory[16'h20] <= 16'h0;
				memory[16'h21] <= 16'h0;
				memory[16'h22] <= 16'h0;
				memory[16'h23] <= 16'h6000;
				memory[16'h24] <= 16'hf01c; // TEST #1-1 : LHI (= 0x0000)
				memory[16'h25] <= 16'h6100;
				memory[16'h26] <= 16'hf41c; // TEST #1-2 : LHI (= 0x0000)
				memory[16'h27] <= 16'h6200;
				memory[16'h28] <= 16'hf81c; // TEST #1-3 : LHI (= 0x0000)
				memory[16'h29] <= 16'h6300;
				memory[16'h2a] <= 16'hfc1c; // TEST #1-4 : LHI (= 0x0000) 
				memory[16'h2b] <= 16'h4401;
				memory[16'h2c] <= 16'hf01c; // TEST #2-1 : ADI (= 0x0001)
				memory[16'h2d] <= 16'h4001;
				memory[16'h2e] <= 16'hf01c; // TEST #2-2 : ADI (= 0x0002)
				memory[16'h2f] <= 16'h5901;
				memory[16'h30] <= 16'hf41c; // TEST #3-1 : ORI (= 0x0001)
				memory[16'h31] <= 16'h5502;
				memory[16'h32] <= 16'hf41c; // TEST #3-2 : ORI (= 0x0003)
				memory[16'h33] <= 16'h5503;
				memory[16'h34] <= 16'hf41c; // TEST #3-3 : ORI (= 0x0003)
				memory[16'h35] <= 16'hf2c0;
				memory[16'h36] <= 16'hfc1c; // TEST #4-1 : ADD (= 0x0002)
				memory[16'h37] <= 16'hf6c0;
				memory[16'h38] <= 16'hfc1c; // TEST #4-2 : ADD (= 0x0003)
				memory[16'h39] <= 16'hf1c0;
				memory[16'h3a] <= 16'hfc1c; // TEST #4-3 : ADD (= 0x0005)
				memory[16'h3b] <= 16'hf2c1;
				memory[16'h3c] <= 16'hfc1c; // TEST #5-1 : SUB (= 0x0002)
				memory[16'h3d] <= 16'hf8c1;
				memory[16'h3e] <= 16'hfc1c; // TEST #5-2 : SUB (= 0xFFFE)
				memory[16'h3f] <= 16'hf6c1;
				memory[16'h40] <= 16'hfc1c; // TEST #5-3 : SUB (= 0x0003)
				memory[16'h41] <= 16'hf9c1;
				memory[16'h42] <= 16'hfc1c; // TEST #5-4 : SUB (= 0xFFFD)
				memory[16'h43] <= 16'hf1c1;
				memory[16'h44] <= 16'hfc1c; // TEST #5-5 : SUB (= 0xFFFF)
				memory[16'h45] <= 16'hf4c1;
				memory[16'h46] <= 16'hfc1c; // TEST #5-6 : SUB (= 0x0001)
				memory[16'h47] <= 16'hf2c2;
				memory[16'h48] <= 16'hfc1c; // TEST #6-1 : AND (= 0x0000)
				memory[16'h49] <= 16'hf6c2;
				memory[16'h4a] <= 16'hfc1c; // TEST #6-2 : AND (= 0x0000)
				memory[16'h4b] <= 16'hf1c2;
				memory[16'h4c] <= 16'hfc1c; // TEST #6-3 : AND (= 0x0002)
				memory[16'h4d] <= 16'hf2c3;
				memory[16'h4e] <= 16'hfc1c; // TEST #7-1 : ORR (= 0x0002)
				memory[16'h4f] <= 16'hf6c3;
				memory[16'h50] <= 16'hfc1c; // TEST #7-2 : ORR (= 0x0003)
				memory[16'h51] <= 16'hf1c3;
				memory[16'h52] <= 16'hfc1c; // TEST #7-3 : ORR (= 0x0003)
				memory[16'h53] <= 16'hf0c4;
				memory[16'h54] <= 16'hfc1c; // TEST #8-1 : NOT (= 0xFFFD)
				memory[16'h55] <= 16'hf4c4;
				memory[16'h56] <= 16'hfc1c; // TEST #8-2 : NOT (= 0xFFFC)
				memory[16'h57] <= 16'hf8c4;
				memory[16'h58] <= 16'hfc1c; // TEST #8-3 : NOT (= 0xFFFF)
				memory[16'h59] <= 16'hf0c5;
				memory[16'h5a] <= 16'hfc1c; // TEST #9-1 : TCP (= 0xFFFE)
				memory[16'h5b] <= 16'hf4c5;
				memory[16'h5c] <= 16'hfc1c; // TEST #9-2 : TCP (= 0xFFFD)
				memory[16'h5d] <= 16'hf8c5;
				memory[16'h5e] <= 16'hfc1c; // TEST #9-3 : TCP (= 0x0000)
				memory[16'h5f] <= 16'hf0c6;
				memory[16'h60] <= 16'hfc1c; // TEST #10-1 : SHL (= 0x0004)
				memory[16'h61] <= 16'hf4c6;
				memory[16'h62] <= 16'hfc1c; // TEST #10-2 : SHL (= 0x0006)
				memory[16'h63] <= 16'hf8c6;
				memory[16'h64] <= 16'hfc1c; // TEST #10-3 : SHL (= 0x0000)
				memory[16'h65] <= 16'hf0c7;
				memory[16'h66] <= 16'hfc1c; // TEST #11-1 : SHR (= 0x0001)
				memory[16'h67] <= 16'hf4c7;
				memory[16'h68] <= 16'hfc1c; // TEST #11-2 : SHR (= 0x0001)
				memory[16'h69] <= 16'hf8c7;
				memory[16'h6a] <= 16'hfc1c; // TEST #11-3 : SHR (= 0x0000)
				memory[16'h6b] <= 16'h7801;
				memory[16'h6c] <= 16'hf01c; // TEST #12-1 : LWD (= 0x0001)
				memory[16'h6d] <= 16'h7902;
				memory[16'h6e] <= 16'hf41c; // TEST #12-2 : LWD (= 0xFFFF)
				memory[16'h6f] <= 16'h8901;
				memory[16'h70] <= 16'h8802;
				memory[16'h71] <= 16'h7801;
				memory[16'h72] <= 16'hf01c; // TEST #13-1 : WWD (= 0xFFFF)
				memory[16'h73] <= 16'h7902;
				memory[16'h74] <= 16'hf41c; // TEST #13-2 : WWD (= 0x0001)
				memory[16'h75] <= 16'h9076;
				memory[16'h76] <= 16'hf01c; // JMP0
				memory[16'h77] <= 16'h9079;
				memory[16'h78] <= 16'hf01d;
				memory[16'h79] <= 16'hf41c; // JMP1
				memory[16'h7a] <= 16'hb01;
				memory[16'h7b] <= 16'h907d;
				memory[16'h7c] <= 16'hf01d; // BNE1
				memory[16'h7d] <= 16'hf01c; // BNE2
				memory[16'h7e] <= 16'h601;
				memory[16'h7f] <= 16'hf01d;
				memory[16'h80] <= 16'hf41c; // BNE3
				memory[16'h81] <= 16'h1601;
				memory[16'h82] <= 16'h9084;
				memory[16'h83] <= 16'hf01d; // BEQ1
				memory[16'h84] <= 16'hf01c; // BEQ2
				memory[16'h85] <= 16'h1b01;
				memory[16'h86] <= 16'hf01d;
				memory[16'h87] <= 16'hf41c; // BEQ3
				memory[16'h88] <= 16'h2001;
				memory[16'h89] <= 16'h908b;
				memory[16'h8a] <= 16'hf01d; // BGZ1
				memory[16'h8b] <= 16'hf01c; // BGZ2
				memory[16'h8c] <= 16'h2401;
				memory[16'h8d] <= 16'hf01d;
				memory[16'h8e] <= 16'hf41c; // BGZ3
				memory[16'h8f] <= 16'h2801;
				memory[16'h90] <= 16'h9092;
				memory[16'h91] <= 16'hf01d; // BGZ4
				memory[16'h92] <= 16'hf01c; // BGZ5
				memory[16'h93] <= 16'h3001;
				memory[16'h94] <= 16'hf01d;
				memory[16'h95] <= 16'hf41c; // BLZ1
				memory[16'h96] <= 16'h3401;
				memory[16'h97] <= 16'h9099;
				memory[16'h98] <= 16'hf01d; // BLZ2
				memory[16'h99] <= 16'hf01c; // BLZ3
				memory[16'h9a] <= 16'h3801;
				memory[16'h9b] <= 16'h909d;
				memory[16'h9c] <= 16'hf01d; // BLZ4
				memory[16'h9d] <= 16'hf41c; // BLZ5
				memory[16'h9e] <= 16'ha0af;
				memory[16'h9f] <= 16'hf01c; // ; TEST #19-1 : JAL & JPR (= 0xFFFF)
				memory[16'ha0] <= 16'ha0ae;
				memory[16'ha1] <= 16'hf01d;
				memory[16'ha2] <= 16'hf41c; // ; TEST #19-2 : JAL & JPR (= 0x0001)
				memory[16'ha3] <= 16'h6300; 
				memory[16'ha4] <= 16'h5f03;
				memory[16'ha5] <= 16'h6000;
				memory[16'ha6] <= 16'h4005;
				memory[16'ha7] <= 16'ha0b2;
				memory[16'ha8] <= 16'hf01c; // ; TEST #19-3 : JAL & JPR (= 0x0008)
				memory[16'ha9] <= 16'h90b1;
				memory[16'haa] <= 16'h4900; // PREFIB2
				memory[16'hab] <= 16'hf41a;
				memory[16'hac] <= 16'hf01c; // ; TEST #20 : JAL & JRL & JPR (= 0x0022)
				memory[16'had] <= 16'hf01d; // ; FINISHED
				memory[16'hae] <= 16'h4a01; // SIMPLE2
				memory[16'haf] <= 16'hf819; // SIMPLE1
				memory[16'hb0] <= 16'hf01d;
				memory[16'hb1] <= 16'ha0aa; // PREFIB1
				memory[16'hb2] <= 16'h41ff; // FIB1
				memory[16'hb3] <= 16'h2404;
				memory[16'hb4] <= 16'h6000;
				memory[16'hb5] <= 16'h5001;
				memory[16'hb6] <= 16'hf819;
				memory[16'hb7] <= 16'hf01d;
				memory[16'hb8] <= 16'h8e00; // FIBRECUR
				memory[16'hb9] <= 16'h8c01;
				memory[16'hba] <= 16'h4f02;
				memory[16'hbb] <= 16'h40fe;
				memory[16'hbc] <= 16'ha0b2;
				memory[16'hbd] <= 16'h7dff;
				memory[16'hbe] <= 16'h8cff;
				memory[16'hbf] <= 16'h44ff;
				memory[16'hc0] <= 16'ha0b2;
				memory[16'hc1] <= 16'h7dff;
				memory[16'hc2] <= 16'h7efe;
				memory[16'hc3] <= 16'hf100;
				memory[16'hc4] <= 16'h4ffe;
				memory[16'hc5] <= 16'hf819;
				memory[16'hc6] <= 16'hf01d;
			end
		else
			begin
				if(read_m1) begin
					if (count1 == 0 && requested_address1 == address1 && inputReady1 == 1) begin
						// data already given but address is not changed. do nothing
					end else if (count1 < `MEM_STALL_COUNT - 1) begin
						// increase count
						count1 <= count1 + 1;
						inputReady1 <= 0;
					end else begin
						// count is full. return data and reset count
						count1 <= 0;
						requested_address1 <= address1;
						if (requested_address1 == address1) begin
							inputReady1 <= 1;
							data1 <= memory[address1];
						end
					end
				end
				
				if(read_m2) begin
					if (count2 < `MEM_STALL_COUNT - 1) begin
						// increase count
						count2 <= count2 + 1;
						inputReady2 <= 0;
					end else begin
						// count is full. return data and reset count
						count2 <= 0;
						requested_address2 <= address2;
						if (requested_address2 == address2) begin
							inputReady2 <= 1;
							output_data2 <= memory[address2];
						end
					end
				end

				if(write_m2) begin
					if (count2 < `MEM_STALL_COUNT - 1) begin
						// increase count
						count2 <= count2 + 1;
						ackOutput2 <= 0;
					end else begin
						// count is full. write data and reset count
						count2 <= 0;
						requested_address2 <= address2;
						if (requested_address2 == address2) begin
							ackOutput2 <= 1;
							memory[address2] <= data2;
						end
					end
				end
			end

endmodule