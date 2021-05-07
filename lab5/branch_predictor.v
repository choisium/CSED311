`include "opcodes.v" 

module branch_predictor_always_not_taken(clk, reset_n, PC, is_flush, is_BJ_type, actual_next_PC, actual_PC, next_PC);

	input clk;
	input reset_n;
	input [`WORD_SIZE-1:0] PC;
	input is_flush;
	input is_BJ_type;
	input [`WORD_SIZE-1:0] actual_next_PC; //computed actual next PC from branch resolve stage
	input [`WORD_SIZE-1:0] actual_PC; // PC from branch resolve stage

	output [`WORD_SIZE-1:0] next_PC;

	assign next_PC = (is_flush | !(PC < 16'hc6))? actual_next_PC: PC + 1;

endmodule


module branch_predictor_always_taken(clk, reset_n, PC, is_flush, is_BJ_type, actual_taken_PC, actual_next_PC, actual_PC, next_PC);

	input clk;
	input reset_n;
	input [`WORD_SIZE-1:0] PC;
	input is_flush;
	input is_BJ_type;
	input [`WORD_SIZE-1:0] actual_taken_PC; // PC in case of always taken from branch resolve stage
	input [`WORD_SIZE-1:0] actual_next_PC; // computed actual next PC from branch resolve stage
	input [`WORD_SIZE-1:0] actual_PC; // PC from branch resolve stage

	output reg [`WORD_SIZE-1:0] next_PC;

	integer i;
	reg [`TAG_SIZE:0] tagtable [0:(2**`IDX_SIZE)-1];
	reg [`WORD_SIZE-1:0] btb [0:(2**`IDX_SIZE)-1];

	wire [`TAG_SIZE-1:0] tag; wire [`IDX_SIZE-1:0] idx;
	assign tag = PC[`WORD_SIZE-1:`IDX_SIZE];
	assign idx = PC[`IDX_SIZE-1:0];

	initial begin
		tagtable[0] <= ~0;	tagtable[1] <= ~0;	tagtable[2] <= ~0;	tagtable[3] <= ~0;
		tagtable[4] <= ~0;	tagtable[5] <= ~0;	tagtable[6] <= ~0;	tagtable[7] <= ~0;
		tagtable[8] <= ~0;	tagtable[9] <= ~0;	tagtable[10] <= ~0;	tagtable[11] <= ~0;
		tagtable[12] <= ~0;	tagtable[13] <= ~0;	tagtable[14] <= ~0;	tagtable[15] <= ~0;
		tagtable[16] <= ~0;	tagtable[17] <= ~0;	tagtable[18] <= ~0;	tagtable[19] <= ~0;
		tagtable[20] <= ~0;	tagtable[21] <= ~0;	tagtable[22] <= ~0;	tagtable[23] <= ~0;
		tagtable[24] <= ~0;	tagtable[25] <= ~0;	tagtable[26] <= ~0;	tagtable[27] <= ~0;
		tagtable[28] <= ~0;	tagtable[29] <= ~0;	tagtable[30] <= ~0;	tagtable[31] <= ~0;

		btb[0] <= ~0;	btb[1] <= ~0;	btb[2] <= ~0;	btb[3] <= ~0;
		btb[4] <= ~0;	btb[5] <= ~0;	btb[6] <= ~0;	btb[7] <= ~0;
		btb[8] <= ~0;	btb[9] <= ~0;	btb[10] <= ~0;	btb[11] <= ~0;
		btb[12] <= ~0;	btb[13] <= ~0;	btb[14] <= ~0;	btb[15] <= ~0;
		btb[16] <= ~0;	btb[17] <= ~0;	btb[18] <= ~0;	btb[19] <= ~0;
		btb[20] <= ~0;	btb[21] <= ~0;	btb[22] <= ~0;	btb[23] <= ~0;
		btb[24] <= ~0;	btb[25] <= ~0;	btb[26] <= ~0;	btb[27] <= ~0;
		btb[28] <= ~0;	btb[29] <= ~0;	btb[30] <= ~0;	btb[31] <= ~0;
	end

	always @(posedge clk) begin
		if (!reset_n) begin
			tagtable[0] <= ~0;	tagtable[1] <= ~0;	tagtable[2] <= ~0;	tagtable[3] <= ~0;
			tagtable[4] <= ~0;	tagtable[5] <= ~0;	tagtable[6] <= ~0;	tagtable[7] <= ~0;
			tagtable[8] <= ~0;	tagtable[9] <= ~0;	tagtable[10] <= ~0;	tagtable[11] <= ~0;
			tagtable[12] <= ~0;	tagtable[13] <= ~0;	tagtable[14] <= ~0;	tagtable[15] <= ~0;
			tagtable[16] <= ~0;	tagtable[17] <= ~0;	tagtable[18] <= ~0;	tagtable[19] <= ~0;
			tagtable[20] <= ~0;	tagtable[21] <= ~0;	tagtable[22] <= ~0;	tagtable[23] <= ~0;
			tagtable[24] <= ~0;	tagtable[25] <= ~0;	tagtable[26] <= ~0;	tagtable[27] <= ~0;
			tagtable[28] <= ~0;	tagtable[29] <= ~0;	tagtable[30] <= ~0;	tagtable[31] <= ~0;

			btb[0] <= ~0;	btb[1] <= ~0;	btb[2] <= ~0;	btb[3] <= ~0;
			btb[4] <= ~0;	btb[5] <= ~0;	btb[6] <= ~0;	btb[7] <= ~0;
			btb[8] <= ~0;	btb[9] <= ~0;	btb[10] <= ~0;	btb[11] <= ~0;
			btb[12] <= ~0;	btb[13] <= ~0;	btb[14] <= ~0;	btb[15] <= ~0;
			btb[16] <= ~0;	btb[17] <= ~0;	btb[18] <= ~0;	btb[19] <= ~0;
			btb[20] <= ~0;	btb[21] <= ~0;	btb[22] <= ~0;	btb[23] <= ~0;
			btb[24] <= ~0;	btb[25] <= ~0;	btb[26] <= ~0;	btb[27] <= ~0;
			btb[28] <= ~0;	btb[29] <= ~0;	btb[30] <= ~0;	btb[31] <= ~0;

		end else begin
			if (is_BJ_type) begin
				tagtable[actual_PC[`IDX_SIZE-1:0]] <= actual_PC[`WORD_SIZE-1:`IDX_SIZE];
				btb[actual_PC[`IDX_SIZE-1:0]] <= actual_taken_PC;
			end
		end
	end

	always @(*) begin
		if (is_flush) begin
			next_PC = actual_next_PC;
		end else if (tagtable[idx] == tag) begin
			next_PC = btb[idx];
		end else begin
			next_PC = !(PC < 16'hc6)? PC: PC + 1;
		end
	end

endmodule


module branch_predictor_global_predictor(clk, reset_n, PC, is_flush, is_BJ_type, actual_taken_PC, actual_next_PC, actual_PC, next_PC);

	input clk;
	input reset_n;
	input [`WORD_SIZE-1:0] PC;
	input is_flush;
	input is_BJ_type;
	input [`WORD_SIZE-1:0] actual_taken_PC; // PC in case of always taken from branch resolve stage
	input [`WORD_SIZE-1:0] actual_next_PC; //computed actual next PC from branch resolve stage
	input [`WORD_SIZE-1:0] actual_PC; // PC from branch resolve stage

	output reg [`WORD_SIZE-1:0] next_PC;

	integer i;
	reg [`TAG_SIZE:0] tagtable [0:(2**`IDX_SIZE)-1];
	reg [`WORD_SIZE-1:0] btb [0:(2**`IDX_SIZE)-1];

	// 2-bit global predictor
	reg [1:0] sat_cnt; 
	reg [1:0] hys_cnt;

	// 2**IDX 2-bit state machines
	reg [1:0] bht_sat [0:(2**`IDX_SIZE)-1];
	reg [1:0] bht_hys [0:(2**`IDX_SIZE)-1];

	wire [`TAG_SIZE-1:0] tag; wire [`IDX_SIZE-1:0] idx;
	assign tag = PC[`WORD_SIZE-1:`IDX_SIZE];
	assign idx = PC[`IDX_SIZE-1:0];

	initial begin
		tagtable[0] <= ~0;	tagtable[1] <= ~0;	tagtable[2] <= ~0;	tagtable[3] <= ~0;
		tagtable[4] <= ~0;	tagtable[5] <= ~0;	tagtable[6] <= ~0;	tagtable[7] <= ~0;
		tagtable[8] <= ~0;	tagtable[9] <= ~0;	tagtable[10] <= ~0;	tagtable[11] <= ~0;
		tagtable[12] <= ~0;	tagtable[13] <= ~0;	tagtable[14] <= ~0;	tagtable[15] <= ~0;
		tagtable[16] <= ~0;	tagtable[17] <= ~0;	tagtable[18] <= ~0;	tagtable[19] <= ~0;
		tagtable[20] <= ~0;	tagtable[21] <= ~0;	tagtable[22] <= ~0;	tagtable[23] <= ~0;
		tagtable[24] <= ~0;	tagtable[25] <= ~0;	tagtable[26] <= ~0;	tagtable[27] <= ~0;
		tagtable[28] <= ~0;	tagtable[29] <= ~0;	tagtable[30] <= ~0;	tagtable[31] <= ~0;

		btb[0] <= ~0;	btb[1] <= ~0;	btb[2] <= ~0;	btb[3] <= ~0;
		btb[4] <= ~0;	btb[5] <= ~0;	btb[6] <= ~0;	btb[7] <= ~0;
		btb[8] <= ~0;	btb[9] <= ~0;	btb[10] <= ~0;	btb[11] <= ~0;
		btb[12] <= ~0;	btb[13] <= ~0;	btb[14] <= ~0;	btb[15] <= ~0;
		btb[16] <= ~0;	btb[17] <= ~0;	btb[18] <= ~0;	btb[19] <= ~0;
		btb[20] <= ~0;	btb[21] <= ~0;	btb[22] <= ~0;	btb[23] <= ~0;
		btb[24] <= ~0;	btb[25] <= ~0;	btb[26] <= ~0;	btb[27] <= ~0;
		btb[28] <= ~0;	btb[29] <= ~0;	btb[30] <= ~0;	btb[31] <= ~0;

		bht_sat[0] <= ~0;	bht_sat[1] <= ~0;	bht_sat[2] <= ~0;	bht_sat[3] <= ~0;
		bht_sat[4] <= ~0;	bht_sat[5] <= ~0;	bht_sat[6] <= ~0;	bht_sat[7] <= ~0;
		bht_sat[8] <= ~0;	bht_sat[9] <= ~0;	bht_sat[10] <= ~0;	bht_sat[11] <= ~0;
		bht_sat[12] <= ~0;	bht_sat[13] <= ~0;	bht_sat[14] <= ~0;	bht_sat[15] <= ~0;
		bht_sat[16] <= ~0;	bht_sat[17] <= ~0;	bht_sat[18] <= ~0;	bht_sat[19] <= ~0;
		bht_sat[20] <= ~0;	bht_sat[21] <= ~0;	bht_sat[22] <= ~0;	bht_sat[23] <= ~0;
		bht_sat[24] <= ~0;	bht_sat[25] <= ~0;	bht_sat[26] <= ~0;	bht_sat[27] <= ~0;
		bht_sat[28] <= ~0;	bht_sat[29] <= ~0;	bht_sat[30] <= ~0;	bht_sat[31] <= ~0;

		bht_hys[0] <= ~0;	bht_hys[1] <= ~0;	bht_hys[2] <= ~0;	bht_hys[3] <= ~0;
		bht_hys[4] <= ~0;	bht_hys[5] <= ~0;	bht_hys[6] <= ~0;	bht_hys[7] <= ~0;
		bht_hys[8] <= ~0;	bht_hys[9] <= ~0;	bht_hys[10] <= ~0;	bht_hys[11] <= ~0;
		bht_hys[12] <= ~0;	bht_hys[13] <= ~0;	bht_hys[14] <= ~0;	bht_hys[15] <= ~0;
		bht_hys[16] <= ~0;	bht_hys[17] <= ~0;	bht_hys[18] <= ~0;	bht_hys[19] <= ~0;
		bht_hys[20] <= ~0;	bht_hys[21] <= ~0;	bht_hys[22] <= ~0;	bht_hys[23] <= ~0;
		bht_hys[24] <= ~0;	bht_hys[25] <= ~0;	bht_hys[26] <= ~0;	bht_hys[27] <= ~0;
		bht_hys[28] <= ~0;	bht_hys[29] <= ~0;	bht_hys[30] <= ~0;	bht_hys[31] <= ~0;

		sat_cnt <= 0;
		hys_cnt <= 0;
	end

	always @(posedge clk) begin
		if (!reset_n) begin
			tagtable[0] <= ~0;	tagtable[1] <= ~0;	tagtable[2] <= ~0;	tagtable[3] <= ~0;
			tagtable[4] <= ~0;	tagtable[5] <= ~0;	tagtable[6] <= ~0;	tagtable[7] <= ~0;
			tagtable[8] <= ~0;	tagtable[9] <= ~0;	tagtable[10] <= ~0;	tagtable[11] <= ~0;
			tagtable[12] <= ~0;	tagtable[13] <= ~0;	tagtable[14] <= ~0;	tagtable[15] <= ~0;
			tagtable[16] <= ~0;	tagtable[17] <= ~0;	tagtable[18] <= ~0;	tagtable[19] <= ~0;
			tagtable[20] <= ~0;	tagtable[21] <= ~0;	tagtable[22] <= ~0;	tagtable[23] <= ~0;
			tagtable[24] <= ~0;	tagtable[25] <= ~0;	tagtable[26] <= ~0;	tagtable[27] <= ~0;
			tagtable[28] <= ~0;	tagtable[29] <= ~0;	tagtable[30] <= ~0;	tagtable[31] <= ~0;

			btb[0] <= ~0;	btb[1] <= ~0;	btb[2] <= ~0;	btb[3] <= ~0;
			btb[4] <= ~0;	btb[5] <= ~0;	btb[6] <= ~0;	btb[7] <= ~0;
			btb[8] <= ~0;	btb[9] <= ~0;	btb[10] <= ~0;	btb[11] <= ~0;
			btb[12] <= ~0;	btb[13] <= ~0;	btb[14] <= ~0;	btb[15] <= ~0;
			btb[16] <= ~0;	btb[17] <= ~0;	btb[18] <= ~0;	btb[19] <= ~0;
			btb[20] <= ~0;	btb[21] <= ~0;	btb[22] <= ~0;	btb[23] <= ~0;
			btb[24] <= ~0;	btb[25] <= ~0;	btb[26] <= ~0;	btb[27] <= ~0;
			btb[28] <= ~0;	btb[29] <= ~0;	btb[30] <= ~0;	btb[31] <= ~0;

			bht_sat[0] <= ~0;	bht_sat[1] <= ~0;	bht_sat[2] <= ~0;	bht_sat[3] <= ~0;
			bht_sat[4] <= ~0;	bht_sat[5] <= ~0;	bht_sat[6] <= ~0;	bht_sat[7] <= ~0;
			bht_sat[8] <= ~0;	bht_sat[9] <= ~0;	bht_sat[10] <= ~0;	bht_sat[11] <= ~0;
			bht_sat[12] <= ~0;	bht_sat[13] <= ~0;	bht_sat[14] <= ~0;	bht_sat[15] <= ~0;
			bht_sat[16] <= ~0;	bht_sat[17] <= ~0;	bht_sat[18] <= ~0;	bht_sat[19] <= ~0;
			bht_sat[20] <= ~0;	bht_sat[21] <= ~0;	bht_sat[22] <= ~0;	bht_sat[23] <= ~0;
			bht_sat[24] <= ~0;	bht_sat[25] <= ~0;	bht_sat[26] <= ~0;	bht_sat[27] <= ~0;
			bht_sat[28] <= ~0;	bht_sat[29] <= ~0;	bht_sat[30] <= ~0;	bht_sat[31] <= ~0;

			bht_hys[0] <= ~0;	bht_hys[1] <= ~0;	bht_hys[2] <= ~0;	bht_hys[3] <= ~0;
			bht_hys[4] <= ~0;	bht_hys[5] <= ~0;	bht_hys[6] <= ~0;	bht_hys[7] <= ~0;
			bht_hys[8] <= ~0;	bht_hys[9] <= ~0;	bht_hys[10] <= ~0;	bht_hys[11] <= ~0;
			bht_hys[12] <= ~0;	bht_hys[13] <= ~0;	bht_hys[14] <= ~0;	bht_hys[15] <= ~0;
			bht_hys[16] <= ~0;	bht_hys[17] <= ~0;	bht_hys[18] <= ~0;	bht_hys[19] <= ~0;
			bht_hys[20] <= ~0;	bht_hys[21] <= ~0;	bht_hys[22] <= ~0;	bht_hys[23] <= ~0;
			bht_hys[24] <= ~0;	bht_hys[25] <= ~0;	bht_hys[26] <= ~0;	bht_hys[27] <= ~0;
			bht_hys[28] <= ~0;	bht_hys[29] <= ~0;	bht_hys[30] <= ~0;	bht_hys[31] <= ~0;

			sat_cnt <= 0;
			hys_cnt <= 0;

		end else begin
			if (is_BJ_type) begin
				tagtable[actual_PC[`IDX_SIZE-1:0]] <= actual_PC[`WORD_SIZE-1:`IDX_SIZE];
				btb[actual_PC[`IDX_SIZE-1:0]] <= actual_taken_PC;
				
				if(actual_next_PC != actual_taken_PC) begin // actually not taken
						
					// global saturation counter
					if(sat_cnt == 2'b00)		sat_cnt <= 2'b00;
					else if(sat_cnt == 2'b01) 	sat_cnt <= 2'b00;
					else if(sat_cnt == 2'b10) 	sat_cnt <= 2'b01;
					else 						sat_cnt <= 2'b10;

					// global hysteresis counter
					if(hys_cnt == 2'b00)		hys_cnt <= 2'b00;
					else if(hys_cnt == 2'b01) 	hys_cnt <= 2'b00;
					else if(hys_cnt == 2'b10) 	hys_cnt <= 2'b00;
					else 						hys_cnt <= 2'b10;

					// indexed saturation counter
					if(bht_sat[actual_PC[`IDX_SIZE-1:0]] == 2'b00)		bht_sat[actual_PC[`IDX_SIZE-1:0]] <= 2'b00;
					else if(bht_sat[actual_PC[`IDX_SIZE-1:0]] == 2'b01) bht_sat[actual_PC[`IDX_SIZE-1:0]] <= 2'b00;
					else if(bht_sat[actual_PC[`IDX_SIZE-1:0]] == 2'b10) bht_sat[actual_PC[`IDX_SIZE-1:0]] <= 2'b01;
					else 												bht_sat[actual_PC[`IDX_SIZE-1:0]] <= 2'b10;

					// indexed hysteresis counter
					if(bht_hys[actual_PC[`IDX_SIZE-1:0]] == 2'b00)		bht_hys[actual_PC[`IDX_SIZE-1:0]] <= 2'b00;
					else if(bht_hys[actual_PC[`IDX_SIZE-1:0]] == 2'b01) bht_hys[actual_PC[`IDX_SIZE-1:0]] <= 2'b00;
					else if(bht_hys[actual_PC[`IDX_SIZE-1:0]] == 2'b10) bht_hys[actual_PC[`IDX_SIZE-1:0]] <= 2'b00;
					else 												bht_hys[actual_PC[`IDX_SIZE-1:0]] <= 2'b10;
				
				end else begin // actually taken

					// global saturation counter
					if(sat_cnt == 2'b00) 		sat_cnt <= 2'b01;
					else if(sat_cnt == 2'b01) 	sat_cnt <= 2'b10;
					else if(sat_cnt == 2'b10) 	sat_cnt <= 2'b11;
					else 						sat_cnt <= 2'b11;

					// global hysteresis counter
					if(hys_cnt == 2'b00) 		hys_cnt <= 2'b01;
					else if(hys_cnt == 2'b01) 	hys_cnt <= 2'b11;
					else if(hys_cnt == 2'b10) 	hys_cnt <= 2'b11;
					else 						hys_cnt <= 2'b11;

					// indexed saturation counter
					if(bht_sat[actual_PC[`IDX_SIZE-1:0]] == 2'b00) 		bht_sat[actual_PC[`IDX_SIZE-1:0]] <= 2'b01;
					else if(bht_sat[actual_PC[`IDX_SIZE-1:0]] == 2'b01) bht_sat[actual_PC[`IDX_SIZE-1:0]] <= 2'b10;
					else if(bht_sat[actual_PC[`IDX_SIZE-1:0]] == 2'b10) bht_sat[actual_PC[`IDX_SIZE-1:0]] <= 2'b11;
					else 												bht_sat[actual_PC[`IDX_SIZE-1:0]] <= 2'b11;

					// indexed hysteresis counter
					if(bht_hys[actual_PC[`IDX_SIZE-1:0]] == 2'b00)		bht_hys[actual_PC[`IDX_SIZE-1:0]] <= 2'b01;
					else if(bht_hys[actual_PC[`IDX_SIZE-1:0]] == 2'b01) bht_hys[actual_PC[`IDX_SIZE-1:0]] <= 2'b11;
					else if(bht_hys[actual_PC[`IDX_SIZE-1:0]] == 2'b10) bht_hys[actual_PC[`IDX_SIZE-1:0]] <= 2'b11;
					else 												bht_hys[actual_PC[`IDX_SIZE-1:0]] <= 2'b11;
				end
			end
		end
	end
	always @(*) begin
		if (is_flush) begin
			next_PC = actual_next_PC;
		end else if (tagtable[idx] == tag) begin
			next_PC = (sat_cnt >= 2'b10)? btb[idx] : (!(PC < 16'hc6)? PC: PC + 1);
			// next_PC = (hys_cnt >= 2'b10)? btb[idx] : (!(PC < 16'hc6)? PC: PC + 1);
			// next_PC = (bht_sat[idx] >= 2'b10)? btb[idx] : (!(PC < 16'hc6)? PC: PC + 1);
			// next_PC = (bht_hys[idx] >= 2'b10)? btb[idx] : (!(PC < 16'hc6)? PC: PC + 1);
		end else begin
			next_PC = !(PC < 16'hc6)? PC: PC + 1;
		end
	end

endmodule