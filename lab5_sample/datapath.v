`include "opcodes.v"
`include "register.v" 
`include "alu.v"
`include "control_unit.v" 
`include "branch_predictor.v"
`include "hazard.v"

module Datapath(clk, reset_n, read_m1, address1, data1, read_m2, write_m2, address2, data2, num_inst, output_port, is_halted);

	input clk;
	input reset_n;

	output read_m1;
	output [`WORD_SIZE-1:0] address1;
	output read_m2;
	output write_m2;
	output [`WORD_SIZE-1:0] address2;

	input [`WORD_SIZE-1:0] data1;
	inout [`WORD_SIZE-1:0] data2;

	output reg [`WORD_SIZE-1:0] num_inst;
	output reg [`WORD_SIZE-1:0] output_port;
	output is_halted;

	//my code

	reg [`WORD_SIZE-1:0] num_inst_WB;
	reg [`WORD_SIZE-1:0] output_port_WB;
	reg is_halted_WB;

    // for hazard avoid & recover
	wire is_stall;
	wire is_flush;
	wire isBJtype;

	// for IF stage
	reg [`WORD_SIZE-1:0] PC;
	
	wire [`WORD_SIZE-1:0] next_PC;
	
	// for IF/ID
	reg [`WORD_SIZE-1:0] IFID_PC;
	reg [`WORD_SIZE-1:0] IFID_PC2;
	reg IFID_flush;
	reg IFID_complete;
	reg [`WORD_SIZE-1:0] IFID_IR;

	// for ID stage
	wire [7:0] ID_imm;
	wire [11:0] ID_target;
	wire [1:0] ID_rs1; //register read port 1 = regRead1
	wire [1:0] ID_rs2; //register read port 2 = regRead2
	wire [1:0] ID_rd;
	wire ID_WB_RegWrite;
	wire ID_WB_MemtoReg;
	wire ID_WB_isHLT;
	wire ID_M_MemWrite;
	wire ID_M_MemRead;
	wire ID_EX_isLHI;
	wire [1:0] ID_EX_branchType;
	wire [1:0] ID_EX_ALUSrcB;
	wire [2:0] ID_EX_FuncCode;
	wire [1:0] ID_EX_PCALUtype;
	wire ID_EX_PCWritecond;
	wire ID_EX_isJtype;
	wire ID_EX_isWWD;

	wire [1:0] regRead1;
	wire [1:0] regRead2;
	wire [`WORD_SIZE-1:0] regReadData1;
	wire [`WORD_SIZE-1:0] regReadData2;

	// for ID/EX
	reg [`WORD_SIZE-1:0] IDEX_PC;
	reg [`WORD_SIZE-1:0] IDEX_PC2;
	reg [`WORD_SIZE-1:0] IDEX_regA;
	reg [`WORD_SIZE-1:0] IDEX_regB;
	reg [7:0] IDEX_imm;
	reg [11:0] IDEX_target;
	reg [1:0] IDEX_rs1;
	reg [1:0] IDEX_rs2;
	reg [1:0] IDEX_rd;

	reg IDEX_WB_RegWrite;
	reg IDEX_WB_MemtoReg;
	reg IDEX_WB_complete;
	reg IDEX_WB_isHLT;

	reg IDEX_M_MemWrite;
	reg IDEX_M_MemRead;

	reg IDEX_EX_isLHI;
	reg [1:0] IDEX_EX_branchType;
	reg [1:0] IDEX_EX_ALUSrcB;
	reg [2:0] IDEX_EX_FuncCode;

	reg [1:0] IDEX_EX_PCALUtype;
	reg IDEX_EX_PCWritecond;
	reg IDEX_EX_isJtype;

	reg IDEX_EX_isWWD;

	// for EX
	wire [`WORD_SIZE-1:0] PCtarget; // PC + target
	wire [1:0] ForwardA;
	wire [1:0] ForwardB;
	wire [`WORD_SIZE-1:0] inputA; //forwarded reg A
	wire [`WORD_SIZE-1:0] inputB; //forwarded reg B
	wire [`WORD_SIZE-1:0] EX_WWD;
	wire [`WORD_SIZE-1:0] EX_ALUOut;

	// for EX/MEM
	reg [`WORD_SIZE-1:0] EXMEM_WWD;
	reg [`WORD_SIZE-1:0] EXMEM_ALUOut;
	reg [`WORD_SIZE-1:0] EXMEM_regB;
	reg [1:0] EXMEM_rd;

	reg EXMEM_WB_RegWrite;
	reg EXMEM_WB_MemtoReg;
	reg EXMEM_WB_complete;
	reg EXMEM_WB_isHLT;

	reg EXMEM_M_MemWrite;
	reg EXMEM_M_MemRead;

	// for MEM
	wire [`WORD_SIZE-1:0] MEM_MemDataRead;
	
	// for MEM/WB
	reg [`WORD_SIZE-1:0] MEMWB_WWD;
	reg [`WORD_SIZE-1:0] MEMWB_MDR;
	reg [`WORD_SIZE-1:0] MEMWB_AOut;
	reg [1:0] MEMWB_rd;

	reg MEMWB_WB_RegWrite;
	reg MEMWB_WB_MemtoReg;
	reg MEMWB_WB_complete;
	reg MEMWB_WB_isHLT;

	// for WB
	wire [`WORD_SIZE-1:0] regWriteData;

	// IF stage
	branch_predictor myBranch_predictor (clk, reset_n, PC, is_flush, isBJtype, PCtarget, IDEX_PC, next_PC);
	assign address1 = PC;
	assign read_m1 = 1;

	// ID stage
	ID myID (clk, reset_n, IFID_IR, ID_imm, ID_target, ID_rs1, ID_rs2 , ID_rd,
 ID_WB_RegWrite, ID_WB_MemtoReg, ID_WB_isHLT, ID_M_MemWrite, ID_M_MemRead, ID_EX_isLHI, ID_EX_branchType, ID_EX_ALUSrcB, ID_EX_FuncCode,
 ID_EX_PCALUtype, ID_EX_PCWritecond, ID_EX_isJtype, ID_EX_isWWD);
	assign regRead1 = ID_rs1;
	assign regRead2 = ID_rs2;
	Register myRegister (clk, reset_n, regRead1, regRead2, MEMWB_rd, MEMWB_WB_RegWrite, regWriteData, regReadData1, regReadData2);	// ID + WB

	hazard_detect myHazardDetect (IFID_IR, IDEX_rd, IDEX_M_MemRead, is_stall);

	// EX stage

	forwarding_unit myFowardingUnit(IDEX_rs1, IDEX_rs2, EXMEM_rd, EXMEM_WB_RegWrite, MEMWB_rd, MEMWB_WB_RegWrite, ForwardA, ForwardB);
	
	assign inputA = (ForwardA == 2'b00 ? IDEX_regA :
	(ForwardA == 2'b01 ? EXMEM_ALUOut:
	(ForwardA == 2'b10 ? regWriteData : 16'bz)));

	assign inputB = (ForwardB == 2'b00 ? IDEX_regB :
	(ForwardB == 2'b01 ? EXMEM_ALUOut:
	(ForwardB == 2'b10 ? regWriteData : 16'bz)));
	
	EX myEX (clk, reset_n, inputA, inputB, IDEX_EX_isLHI, IDEX_EX_branchType, IDEX_EX_ALUSrcB, IDEX_EX_FuncCode, 
		IDEX_EX_PCALUtype, IDEX_EX_PCWritecond, IDEX_EX_isJtype, IDEX_EX_isWWD, IDEX_PC, IDEX_PC2, IDEX_imm, IDEX_target,
		 PCtarget, is_flush, EX_WWD, EX_ALUOut, isBJtype);

	// MEM stage

	assign read_m2 = EXMEM_M_MemRead;
	assign write_m2 = EXMEM_M_MemWrite;
	assign address2 = EXMEM_ALUOut;
	assign data2 = write_m2 ? EXMEM_regB : 16'bz;
	assign MEM_MemDataRead = read_m2 ? data2 : 16'bz;
		

	// WB stage
	assign regWriteData = MEMWB_WB_MemtoReg ? MEMWB_MDR : MEMWB_AOut;
	assign num_inst = num_inst_WB;
	assign output_port = output_port_WB;
	assign is_halted = is_halted_WB;

	always @(posedge clk) begin
		if(!reset_n) begin
			PC <= 0;
			IFID_PC <= 0;
			IFID_PC2 <= 0;
			IFID_flush <= 0;
			IFID_complete <= 0;
			IFID_IR <= 0;
			

			IDEX_WB_RegWrite <= 0;
			IDEX_WB_MemtoReg <= 0;
			IDEX_WB_complete <= 0;
			IDEX_WB_isHLT <= 0;
			IDEX_M_MemWrite <= 0;
			IDEX_M_MemRead <= 0;
			IDEX_EX_isLHI <= 0;
			IDEX_EX_branchType <= 0;
			IDEX_EX_ALUSrcB <= 0;
			IDEX_EX_FuncCode <= 0;
			IDEX_EX_PCALUtype <= 0;
			IDEX_EX_PCWritecond <= 0;
			IDEX_EX_isJtype <= 0;
			IDEX_EX_isWWD <= 0;

			IDEX_PC <= 0;
			IDEX_PC2 <= 0;
			IDEX_regA <= 0;
			IDEX_regB <= 0;
			IDEX_imm <= 0;
			IDEX_target <= 0;
			IDEX_rs1 <= 0;
			IDEX_rs2 <= 0;
			IDEX_rd <= 0;

			EXMEM_WWD <= 0;
			EXMEM_ALUOut <= 0;
			EXMEM_regB <= 0; 
			EXMEM_rd <= 0;
			EXMEM_WB_RegWrite <= 0;
			EXMEM_WB_MemtoReg <= 0;
			EXMEM_WB_complete <= 0;
			EXMEM_WB_isHLT <= 0;
			EXMEM_M_MemWrite <= 0;
			EXMEM_M_MemRead <= 0;

			MEMWB_WWD <= 0;
			MEMWB_MDR <= 0;
			MEMWB_AOut <= 0;
			MEMWB_rd <= 0;
			MEMWB_WB_RegWrite <= 0;
			MEMWB_WB_MemtoReg <= 0;
			MEMWB_WB_complete <= 0;
			MEMWB_WB_isHLT <= 0;

			num_inst_WB <= 0;
			output_port_WB <= 16'bz;
			is_halted_WB <= 0;
		end
		else begin
			if (!is_stall) begin
				// IF stage reg update
				PC <= next_PC;
				IFID_PC <= PC;
				IFID_PC2 <= next_PC;
				IFID_flush <= is_flush;
				IFID_complete <= 1;
				IFID_IR <= data1;
			end
			// ID stage control signal reg update
			if(is_stall||is_flush||IFID_flush) begin
				IDEX_WB_RegWrite <= 0;
				IDEX_WB_MemtoReg <= 0;
				IDEX_WB_complete <= 0;
				IDEX_WB_isHLT <= 0;

				IDEX_M_MemWrite <= 0;
				IDEX_M_MemRead <= 0;

				IDEX_EX_isLHI <= 0;
				IDEX_EX_branchType <= 0;
				IDEX_EX_ALUSrcB <= 0;
				IDEX_EX_FuncCode <= 0;

				IDEX_EX_PCALUtype <= 0;
				IDEX_EX_PCWritecond <= 0;
				IDEX_EX_isJtype <= 0;

				IDEX_EX_isWWD <= 0;
			end
			else begin
				IDEX_WB_RegWrite <= ID_WB_RegWrite;
				IDEX_WB_MemtoReg <= ID_WB_MemtoReg;
				IDEX_WB_complete <= IFID_complete;
				IDEX_WB_isHLT <= ID_WB_isHLT;

				IDEX_M_MemWrite <= ID_M_MemWrite;
				IDEX_M_MemRead <= ID_M_MemRead;

				IDEX_EX_isLHI <= ID_EX_isLHI;
				IDEX_EX_branchType <= ID_EX_branchType;
				IDEX_EX_ALUSrcB <= ID_EX_ALUSrcB;
				IDEX_EX_FuncCode <= ID_EX_FuncCode;

				IDEX_EX_PCALUtype <= ID_EX_PCALUtype;
				IDEX_EX_PCWritecond <= ID_EX_PCWritecond;
				IDEX_EX_isJtype <= ID_EX_isJtype;

				IDEX_EX_isWWD <= ID_EX_isWWD;			
			end
				
			// ID stage reg update
			IDEX_PC <= IFID_PC;
			IDEX_PC2 <= IFID_PC2;
			IDEX_regA <= regReadData1;
			IDEX_regB <= regReadData2;
			IDEX_imm <= ID_imm;
			IDEX_target <= ID_target;
			IDEX_rs1 <= ID_rs1;
			IDEX_rs2 <= ID_rs2;
			IDEX_rd <= ID_rd;

			// EX stage reg update
			EXMEM_WWD <= EX_WWD;
			EXMEM_ALUOut <= EX_ALUOut;
			EXMEM_regB <= inputB;//forwarded 
			EXMEM_rd <= IDEX_rd;

			EXMEM_WB_RegWrite <= IDEX_WB_RegWrite;
			EXMEM_WB_MemtoReg <= IDEX_WB_MemtoReg;
			EXMEM_WB_complete <= IDEX_WB_complete;
			EXMEM_WB_isHLT <= IDEX_WB_isHLT;

			EXMEM_M_MemWrite <= IDEX_M_MemWrite;
			EXMEM_M_MemRead <= IDEX_M_MemRead;

			// MEM stage reg update
			MEMWB_WWD <= EXMEM_WWD;
			MEMWB_MDR <= MEM_MemDataRead;
			MEMWB_AOut <= EXMEM_ALUOut;
			MEMWB_rd <= EXMEM_rd;

			MEMWB_WB_RegWrite <= EXMEM_WB_RegWrite;
			MEMWB_WB_MemtoReg <= EXMEM_WB_MemtoReg;
			MEMWB_WB_complete <= EXMEM_WB_complete;
			MEMWB_WB_isHLT <= EXMEM_WB_isHLT;

			// WB stage reg update
			if(MEMWB_WB_complete) begin			
				num_inst_WB <= num_inst_WB + 1;
			end
			else begin
				num_inst_WB <= num_inst_WB;
			end 
			output_port_WB <= MEMWB_WWD;
			is_halted_WB <= MEMWB_WB_isHLT;

		end
	end
endmodule

module ID(clk, reset_n, IFID_IR, ID_imm, ID_target, ID_rs1, ID_rs2 , ID_rd,
 ID_WB_RegWrite, ID_WB_MemtoReg, ID_WB_isHLT, ID_M_MemWrite, ID_M_MemRead, ID_EX_isLHI, ID_EX_branchType, ID_EX_ALUSrcB, ID_EX_FuncCode,
 ID_EX_PCALUtype, ID_EX_PCWritecond, ID_EX_isJtype, ID_EX_isWWD);
	
	input clk;
	input reset_n;
	input [`WORD_SIZE-1:0] IFID_IR;
	
	output [7:0] ID_imm;
	output [11:0] ID_target;
	output [1:0] ID_rs1; //register read port 1 = regRead1
	output [1:0] ID_rs2; //register read port 2 = regRead2
	output [1:0] ID_rd; 

	output ID_WB_RegWrite;
	output ID_WB_MemtoReg;
	output ID_WB_isHLT;

	output ID_M_MemWrite;
	output ID_M_MemRead;

	output ID_EX_isLHI;
	output [1:0] ID_EX_branchType;
	output [1:0] ID_EX_ALUSrcB;
	output [2:0] ID_EX_FuncCode;

	output [1:0] ID_EX_PCALUtype;
	output ID_EX_PCWritecond;
	output ID_EX_isJtype;

	output ID_EX_isWWD;

	wire [1:0] temp_rd;
	wire [3:0] opCode;
	wire [5:0] InstFunc;

	wire [1:0] RegWritePort; // 00: rt, 01: rd, 10: $2

	assign opCode = IFID_IR[15:12];
	assign ID_rs1 = IFID_IR[11:10];
	assign ID_rs2 = IFID_IR[9:8];
	assign temp_rd = IFID_IR[7:6];
	assign InstFunc = IFID_IR[5:0];
	assign ID_imm = IFID_IR[7:0];
	assign ID_target = IFID_IR[11:0];
	
	control_unit myControlUnit (clk, opCode, InstFunc, reset_n, ID_WB_RegWrite, ID_EX_FuncCode, ID_EX_ALUSrcB, 
			ID_EX_branchType, ID_EX_isLHI, ID_M_MemRead, ID_M_MemWrite, ID_WB_MemtoReg, ID_EX_isJtype, ID_WB_isHLT, ID_EX_isWWD, 
			ID_EX_PCALUtype, ID_EX_PCWritecond, RegWritePort);

	assign ID_rd = (RegWritePort == 2'b00)? ID_rs2 : 
	((RegWritePort == 2'b01)? temp_rd : 
	((RegWritePort == 2'b10)? 2'd2 : 2'bz)); // 00: rt, 01: rd, 10: $2

endmodule

module EX(clk, reset_n, inputA, inputB, IDEX_EX_isLHI, IDEX_EX_branchType, IDEX_EX_ALUSrcB, IDEX_EX_FuncCode, 
		IDEX_EX_PCALUtype, IDEX_EX_PCWritecond, IDEX_EX_isJtype, IDEX_EX_isWWD, IDEX_PC, IDEX_PC2, IDEX_imm, IDEX_target,
		 PCtarget, is_flush, EX_WWD, EX_ALUOut, isBJtype);

	input clk;
	input reset_n;
	input [`WORD_SIZE-1:0] inputA;
	input [`WORD_SIZE-1:0] inputB;

	input IDEX_EX_isLHI;
	input [1:0] IDEX_EX_branchType;
	input [1:0] IDEX_EX_ALUSrcB; // 00 : RegB, 01 : signImm, 10 : zeroImm, 11 : 0
	input [2:0] IDEX_EX_FuncCode;
	input [1:0] IDEX_EX_PCALUtype;
	input IDEX_EX_PCWritecond;
	input IDEX_EX_isJtype;
	input IDEX_EX_isWWD;

	input [`WORD_SIZE-1:0] IDEX_PC;
	input [`WORD_SIZE-1:0] IDEX_PC2;
	input [7:0] IDEX_imm;
	input [11:0] IDEX_target;

	output [`WORD_SIZE-1:0] PCtarget;
	output is_flush;
	output [`WORD_SIZE-1:0] EX_WWD;
	output [`WORD_SIZE-1:0] EX_ALUOut;
	output isBJtype;
	
	wire [`WORD_SIZE-1:0] tempALUOut;
	wire branchCond;
	wire [`WORD_SIZE-1:0] realInputB;
	wire [`WORD_SIZE-1:0] signImm;
	wire [`WORD_SIZE-1:0] PCInputA;

	wire PCPredictCorrect;
	
	assign signImm = {{8{IDEX_imm[7]}},IDEX_imm[7:0]};

	assign realInputB = (IDEX_EX_ALUSrcB == 2'b00)? inputB : 
	((IDEX_EX_ALUSrcB == 2'b01)? signImm : 
	((IDEX_EX_ALUSrcB == 2'b10)? {{8{1'b0}},IDEX_imm[7:0]} : 0 ));

	ALU myALU (inputA, realInputB, IDEX_EX_FuncCode, IDEX_EX_branchType, IDEX_EX_isLHI, tempALUOut, branchCond);

	//IDEX_PC2 -> IDEX_PC + 1 handle for predict success case
	assign PCInputA = (IDEX_EX_PCALUtype == 2'b00) ? (IDEX_PC + 1):
	((IDEX_EX_PCALUtype == 2'b01) ? IDEX_PC: inputA);

	pcALU myPCALU (PCInputA, signImm, IDEX_target, IDEX_EX_PCALUtype, PCtarget, branchCond);

	assign PCPredictCorrect = (IDEX_PC2 == PCtarget); //for branch predictor update //why not?
	assign is_flush = (IDEX_EX_PCWritecond || IDEX_EX_isJtype) && (!PCPredictCorrect);
	assign isBJtype = IDEX_EX_PCWritecond || IDEX_EX_isJtype;
	assign EX_WWD = IDEX_EX_isWWD ? inputA : 16'bz;
	assign EX_ALUOut = IDEX_EX_isJtype ? IDEX_PC+1 : tempALUOut; // IDEX_PC2 -> IDEX_PC+1 change

endmodule



module forwarding_unit(IDEX_rs1, IDEX_rs2, EXMEM_rd, EXMEM_WB_RegWrite, MEMWB_rd, MEMWB_WB_RegWrite, ForwardA, ForwardB);

	input [1:0] IDEX_rs1;
	input [1:0] IDEX_rs2;
	input [1:0] EXMEM_rd;
	input EXMEM_WB_RegWrite;
	input [1:0] MEMWB_rd;
	input MEMWB_WB_RegWrite;
	output [1:0] ForwardA;
	output [1:0] ForwardB;

	wire ForwardA_EXMEM;
	wire ForwardB_EXMEM;
	wire ForwardA_MEMWB;
	wire ForwardB_MEMWB;
	
	assign ForwardA_EXMEM = (IDEX_rs1 == EXMEM_rd) && EXMEM_WB_RegWrite;
	assign ForwardB_EXMEM = (IDEX_rs2 == EXMEM_rd) && EXMEM_WB_RegWrite;
	assign ForwardA_MEMWB = (IDEX_rs1 == MEMWB_rd) && MEMWB_WB_RegWrite;
	assign ForwardB_MEMWB = (IDEX_rs2 == MEMWB_rd) && MEMWB_WB_RegWrite;
	
	assign ForwardA = ForwardA_EXMEM ? 2'b01 : (ForwardA_MEMWB ? 2'b10 : 2'b00);
	assign ForwardB = ForwardB_EXMEM ? 2'b01 : (ForwardB_MEMWB ? 2'b10 : 2'b00);
	
endmodule
