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
		for(i = 0; i < (2**`IDX_SIZE); i=i+1) begin
			tagtable[i] <= ~0;
			btb[i] <= ~0;
		end
	end

	always @(posedge clk) begin
		if (!reset_n) begin
			for(i = 0; i < (2**`IDX_SIZE); i=i+1) begin
				tagtable[i] <= ~0;
				btb[i] <= ~0;
			end
		end else begin
			$display("tagtable: %b, btb: %b", tagtable[idx], btb[idx]);
			$display("idx: %b, tag: %b, is_BJ_type: %b", idx, tag, is_BJ_type);
			if (is_BJ_type) begin
				$display("Update table for BJ type! actual_next_pc: %h, actual_taken_pc: %h", actual_next_PC, actual_taken_PC);
				tagtable[actual_PC[`IDX_SIZE-1:0]] <= actual_PC[`WORD_SIZE-1:`IDX_SIZE];
				btb[actual_PC[`IDX_SIZE-1:0]] <= actual_taken_PC;
			end
		end
	end

	always @(*) begin
		if (is_flush) begin
			$display("Prediction is wrong! actual_pc: %h, actual_next_pc: %h", actual_next_PC, actual_taken_PC);
			next_PC = actual_next_PC;
		end else if (tagtable[idx] == tag) begin
			$display("tag is same! actual_pc: %h, actual_next_pc: %h", actual_PC, actual_next_PC);
			next_PC = btb[idx];
		end else begin
			$display("tag is not same! actual_pc: %h, actual_next_pc: %h", actual_PC, actual_next_PC);
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

	// previous prediction
	reg predict, predict_history;

	wire [`TAG_SIZE-1:0] tag; wire [`IDX_SIZE-1:0] idx;
	assign tag = PC[`WORD_SIZE-1:`IDX_SIZE];
	assign idx = PC[`IDX_SIZE-1:0];

	initial begin
		for(i = 0; i < (2**`IDX_SIZE); i=i+1) begin
			tagtable[i] <= ~0;
			btb[i] <= ~0;
			bht_sat[i] <= 0;
			bht_hys[i] <= 0;
		end
		sat_cnt <= 0;
		hys_cnt <= 0;
		predict_history <= 0;
	end

	always @(posedge clk) begin
		if (!reset_n) begin
			for(i = 0; i < (2**`IDX_SIZE); i=i+1) begin
				tagtable[i] <= ~0;
				btb[i] <= ~0;
				bht_sat[i] <= 0;
				bht_hys[i] <= 0;
			end
			sat_cnt <= 0;
			hys_cnt <= 0;
			predict_history <= 0;

		end else begin
			$display("tagtable: %b, btb: %b", tagtable[idx], btb[idx]);
			$display("idx: %b, tag: %b, is_BJ_type: %b", idx, tag, is_BJ_type);
			
			if (predict) predict_history <= predict;
			else if (is_BJ_type || actual_next_PC == {`WORD_SIZE{1'b0}}) predict_history <= 0;
			else predict_history <= predict_history;

			if (is_BJ_type) begin
				$display("Update table for wrong BJ type! actual_next_pc: %h, actual_taken_pc: %h", actual_next_PC, actual_taken_PC);
				tagtable[actual_PC[`IDX_SIZE-1:0]] <= actual_PC[`WORD_SIZE-1:`IDX_SIZE];
				btb[actual_PC[`IDX_SIZE-1:0]] <= actual_taken_PC;
				
				if (predict_history) begin // predicted as taken
					if (!is_flush) begin // right prediction -> actually taken

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
				
					else begin // wrong prediction -> actually not taken
					
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

					end
				end

				else begin // predicted as not taken
					if (!is_flush) begin // right prediction -> actually not taken

						// global saturation counter
						if(sat_cnt == 2'b00) 		sat_cnt <= 2'b00;
						else if(sat_cnt == 2'b01) 	sat_cnt <= 2'b00;
						else if(sat_cnt == 2'b10) 	sat_cnt <= 2'b01;
						else 						sat_cnt <= 2'b10;

						// global hysteresis counter
						if(hys_cnt == 2'b00) 		hys_cnt <= 2'b00;
						else if(hys_cnt == 2'b01) 	hys_cnt <= 2'b00;
						else if(hys_cnt == 2'b10) 	hys_cnt <= 2'b00;
						else 						hys_cnt <= 2'b10;

						// indexed saturation counter
						if(bht_sat[actual_PC[`IDX_SIZE-1:0]] == 2'b00) 		bht_sat[actual_PC[`IDX_SIZE-1:0]] <= 2'b00;
						else if(bht_sat[actual_PC[`IDX_SIZE-1:0]] == 2'b01) bht_sat[actual_PC[`IDX_SIZE-1:0]] <= 2'b00;
						else if(bht_sat[actual_PC[`IDX_SIZE-1:0]] == 2'b10) bht_sat[actual_PC[`IDX_SIZE-1:0]] <= 2'b01;
						else 												bht_sat[actual_PC[`IDX_SIZE-1:0]] <= 2'b10;

						// indexed hysteresis counter
						if(bht_hys[actual_PC[`IDX_SIZE-1:0]] == 2'b00)		bht_hys[actual_PC[`IDX_SIZE-1:0]] <= 2'b00;
						else if(bht_hys[actual_PC[`IDX_SIZE-1:0]] == 2'b01) bht_hys[actual_PC[`IDX_SIZE-1:0]] <= 2'b00;
						else if(bht_hys[actual_PC[`IDX_SIZE-1:0]] == 2'b10) bht_hys[actual_PC[`IDX_SIZE-1:0]] <= 2'b00;
						else 												bht_hys[actual_PC[`IDX_SIZE-1:0]] <= 2'b10;
					end 
					
					else begin // wrong prediction -> actually taken
					
						// global saturation counter
						if(sat_cnt == 2'b00)		sat_cnt <= 2'b01;
						else if(sat_cnt == 2'b01) 	sat_cnt <= 2'b10;
						else if(sat_cnt == 2'b10) 	sat_cnt <= 2'b11;
						else 						sat_cnt <= 2'b11;

						// global hysteresis counter
						if(hys_cnt == 2'b00)		hys_cnt <= 2'b01;
						else if(hys_cnt == 2'b01) 	hys_cnt <= 2'b11;
						else if(hys_cnt == 2'b10) 	hys_cnt <= 2'b11;
						else 						hys_cnt <= 2'b11;

						// indexed saturation counter
						if(bht_sat[actual_PC[`IDX_SIZE-1:0]] == 2'b00)		bht_sat[actual_PC[`IDX_SIZE-1:0]] <= 2'b01;
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
	end
	always @(*) begin
		if (is_flush) begin
			$display("Prediction is wrong! actual_pc: %h, actual_next_pc: %h", actual_next_PC, actual_taken_PC);
			next_PC = actual_next_PC;
		end else if (tagtable[idx] == tag) begin
			$display("tag is same! actual_pc: %h, actual_next_pc: %h", actual_PC, actual_next_PC);
			next_PC = (sat_cnt >= 2'b10)? btb[idx] : (!(PC < 16'hc6)? PC: PC + 1);
			// next_PC = (hys_cnt >= 2'b10)? btb[idx] : (!(PC < 16'hc6)? PC: PC + 1);
			// next_PC = (bht_sat[idx] >= 2'b10)? btb[idx] : (!(PC < 16'hc6)? PC: PC + 1);
			// next_PC = (bht_hys[idx] >= 2'b10)? btb[idx] : (!(PC < 16'hc6)? PC: PC + 1);
		end else begin
			$display("tag is not same! actual_pc: %h, actual_next_pc: %h", actual_PC, actual_next_PC);
			next_PC = !(PC < 16'hc6)? PC: PC + 1;
		end

		predict = (tagtable[idx] == tag)? ((sat_cnt >= 2'b10)? 1:0) : 0; 
		// predict = (tagtable[idx] == tag)? ((hys_cnt >= 2'b10)? 1:0) : 0; 
		// predict = (tagtable[idx] == tag)? ((bht_sat[idx] >= 2'b10)? 1:0) : 0; 
		// predict = (tagtable[idx] == tag)? ((bht_hys[idx] >= 2'b10)? 1:0) : 0; 
	end

endmodule