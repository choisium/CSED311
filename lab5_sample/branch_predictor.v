`include "opcodes.v" 

module branch_predictor(Clk, Reset_N, PC, isFlush, isBJtype, actualPCtarget, actualPC, nextPC);

input Clk;
input Reset_N;
input [`WORD_SIZE-1:0] PC;
input isFlush;
input isBJtype;
input [`WORD_SIZE-1:0] actualPCtarget;
input [`WORD_SIZE-1:0] actualPC; // from branch resolve stage

output [`WORD_SIZE-1:0] nextPC;

reg [1:0] counter;
reg [`WORD_SIZE-1:0] BTB [0:`WORD_SIZE-1];
reg [11:0] tagTable [0:`WORD_SIZE-1];

wire [11:0] selectedTag;
wire [`WORD_SIZE-1:0] selectedTarget;
wire [3:0] PCBTBidx;
wire [11:0] PCtag;
wire prediction;
wire PCtakenMux;

wire [3:0] actualPCBTBidx;
wire [11:0] actualPCtag;

assign actualPCBTBidx = actualPC[3:0];
assign actualPCtag = actualPC[`WORD_SIZE-1:4];

assign PCBTBidx = PC[3:0];
assign PCtag = PC[`WORD_SIZE-1:4];
assign selectedTag = tagTable[PCBTBidx];
assign selectedTarget = BTB[PCBTBidx];
assign prediction = counter[1];
assign PCtakenMux = prediction && (PCtag === selectedTag) && (selectedTarget !== 16'bz);
assign nextPC = isFlush? actualPCtarget : (PCtakenMux ? selectedTarget : PC+1);

always @(posedge Clk) begin
	if(!Reset_N) begin 
			BTB[16'h0] <= 16'bz;
			BTB[16'h1] <= 16'bz;
			BTB[16'h2] <= 16'bz;
			BTB[16'h3] <= 16'bz;
			BTB[16'h4] <= 16'bz;
			BTB[16'h5] <= 16'bz;
			BTB[16'h6] <= 16'bz;
			BTB[16'h7] <= 16'bz;
			BTB[16'h8] <= 16'bz;
			BTB[16'h9] <= 16'bz;
			BTB[16'ha] <= 16'bz;
			BTB[16'hb] <= 16'bz;
			BTB[16'hc] <= 16'bz;
			BTB[16'hd] <= 16'bz;
			BTB[16'he] <= 16'bz;
			BTB[16'hf] <= 16'bz;
		
			tagTable[16'h0] <= 12'bz;
			tagTable[16'h1] <= 12'bz;
			tagTable[16'h2] <= 12'bz;
			tagTable[16'h3] <= 12'bz;
			tagTable[16'h4] <= 12'bz;
			tagTable[16'h5] <= 12'bz;
			tagTable[16'h6] <= 12'bz;
			tagTable[16'h7] <= 12'bz;
			tagTable[16'h8] <= 12'bz;
			tagTable[16'h9] <= 12'bz;
			tagTable[16'ha] <= 12'bz;
			tagTable[16'hb] <= 12'bz;
			tagTable[16'hc] <= 12'bz;
			tagTable[16'hd] <= 12'bz;
			tagTable[16'he] <= 12'bz;
			tagTable[16'hf] <= 12'bz;

			counter <= 2'b00;
			//counter <= 2'b11;
	end
	else begin
		if(isBJtype) begin
			if(isFlush) begin // prediction wrong
				if(counter == 2'b11) counter <= 2'b10;
				else if(counter == 2'b10) counter <= 2'b00;//2'b01;
				else if(counter == 2'b01) counter <= 2'b11;//2'b10;
				else if(counter == 2'b00) counter <= 2'b01;
			
				BTB[actualPCBTBidx] <= actualPCtarget;
				tagTable[actualPCBTBidx] <= actualPCtag;
			end
			else begin //prediction right
				if(counter == 2'b11) counter <= 2'b11;
				else if(counter == 2'b10) counter <= 2'b11;
				else if(counter == 2'b01) counter <= 2'b00;
				else if(counter == 2'b00) counter <= 2'b00;
			end
		end
	end

end




endmodule
