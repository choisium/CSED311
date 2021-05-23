`include "opcodes.v" 

module control_unit (Clk, opCode, InstFunc, reset_n, regWrite, FuncCode, ALUSrcB, 
branchType, isLHI, MemRead, MemWrite, MemToReg, isJtype, isHLT, isWWD, 
PCALUtype, PCWriteCond, RegWritePort);
	input Clk;
	input [3:0] opCode;
	input [5:0] InstFunc;
	input reset_n;

	output reg regWrite;
	output reg[2:0] FuncCode;
	output reg [1:0] ALUSrcB; // 00 : RegB, 01 : signImm, 10 : zeroImm, 11 : 0
	output reg [1:0] branchType;// 00 : BNE, 01 : BEQ, 10 : BGZ, 11 : BLZ
	output reg isLHI;
	output reg MemRead;
	output reg MemWrite;
	output reg MemToReg;
	output reg isJtype;
	output reg isHLT;
	output reg isWWD;
	output reg [1:0] PCALUtype; //00 : branch,  01: JMP JAL, 10: JPR JRL
	output reg PCWriteCond;
	output reg [1:0] RegWritePort; // 00: rt, 01: rd, 10: $2

	always @(posedge Clk) begin
		if(!reset_n) begin
			regWrite <= 0;
			FuncCode <= 0;
			ALUSrcB <= 0;
			branchType <= 0;
			isLHI <= 0;
			MemRead <= 0;
			MemWrite <= 0;
			MemToReg <= 0;
			isJtype <= 0;
			isHLT <= 0;
			isWWD <= 0;
			PCALUtype <= 2'bz; 
			PCWriteCond <= 0;
			RegWritePort <= 0;
		end
	end
	
	always @(*) begin
		case (opCode)
		`ALU_OP	: begin //common for every Rtype except JPR, JRL
			regWrite = 1;
			FuncCode = 0;
			ALUSrcB = 0;
			branchType = 0;// 00 : BNE, 01 : BEQ, 10 : BGZ, 11 : BLZ
			isLHI = 0;
			MemRead = 0;
			MemWrite = 0;
			MemToReg = 0;
			isJtype = 0; //Jxx case
			isHLT = 0; // hlt case 
			isWWD = 0; // wwd case
			PCALUtype = 2'bz; //00 : branch,  01: JMP JAL, 10: JPR JRL -> Jxx case
			PCWriteCond = 0;
			RegWritePort = 2'b01; // 00: rt, 01: rd, 10: $2 -> JRL case
			case (InstFunc)
				`INST_FUNC_ADD : begin
					FuncCode = `FUNC_ADD;
				end
				`INST_FUNC_SUB : begin
					FuncCode = `FUNC_SUB;					
				end
				`INST_FUNC_AND : begin
					FuncCode = `FUNC_AND;
				end
				`INST_FUNC_ORR : begin
					FuncCode = `FUNC_ORR;
				end
				`INST_FUNC_NOT : begin
					FuncCode = `FUNC_NOT;
				end
				`INST_FUNC_TCP : begin
					FuncCode = `FUNC_TCP;
				end
				`INST_FUNC_SHL : begin
					FuncCode = `FUNC_SHL;
				end
				`INST_FUNC_SHR : begin
					FuncCode = `FUNC_SHR;
				end
				`INST_FUNC_JPR : begin
					regWrite = 0;
					isJtype = 1;
					PCALUtype = 2'b10;
				end
				`INST_FUNC_JRL : begin
					isJtype = 1;
					PCALUtype = 2'b10;
					RegWritePort = 2'b10;
				end
				`INST_FUNC_WWD : begin
					regWrite = 0;
					isWWD = 1;
				end
				`INST_FUNC_HLT : begin
					regWrite = 0;
					isHLT = 1;
				end
			endcase			
		end
		`ADI_OP	: begin
			regWrite = 1;
			FuncCode = `FUNC_ADD;
			ALUSrcB = 2'b01;// 00 : RegB, 01 : signImm, 10 : zeroImm, 11 : 0
			branchType = 0;// 00 : BNE, 01 : BEQ, 10 : BGZ, 11 : BLZ
			isLHI = 0;
			MemRead = 0;
			MemWrite = 0;
			MemToReg = 0;
			isJtype = 0; //Jxx case
			isHLT = 0; // hlt case 
			isWWD = 0; // wwd case
			PCALUtype = 2'bz; //00 : branch,  01: JMP JAL, 10: JPR JRL -> Jxx case
			PCWriteCond = 0;
			RegWritePort = 2'b00; // 00: rt, 01: rd, 10: $2 -> JRL case
		end
		`ORI_OP : begin
			regWrite = 1;
			FuncCode = `FUNC_ORR;
			ALUSrcB = 2'b10;// 00 : RegB, 01 : signImm, 10 : zeroImm, 11 : 0
			branchType = 0;// 00 : BNE, 01 : BEQ, 10 : BGZ, 11 : BLZ
			isLHI = 0;
			MemRead = 0;
			MemWrite = 0;
			MemToReg = 0;
			isJtype = 0; //Jxx case
			isHLT = 0; // hlt case 
			isWWD = 0; // wwd case
			PCALUtype = 2'bz; //00 : branch,  01: JMP JAL, 10: JPR JRL -> Jxx case
			PCWriteCond = 0;
			RegWritePort = 2'b00; // 00: rt, 01: rd, 10: $2 -> JRL case
		end
		`LHI_OP	: begin
			regWrite = 1;
			FuncCode = `FUNC_ADD;
			ALUSrcB = 2'b10;// 00 : RegB, 01 : signImm, 10 : zeroImm, 11 : 0
			branchType = 0;// 00 : BNE, 01 : BEQ, 10 : BGZ, 11 : BLZ
			isLHI = 1;
			MemRead = 0;
			MemWrite = 0;
			MemToReg = 0;
			isJtype = 0; //Jxx case
			isHLT = 0; // hlt case 
			isWWD = 0; // wwd case
			PCALUtype = 2'bz; //00 : branch,  01: JMP JAL, 10: JPR JRL -> Jxx case
			PCWriteCond = 0;
			RegWritePort = 2'b00; // 00: rt, 01: rd, 10: $2 -> JRL case
		end
		`LWD_OP	: begin
			regWrite = 1;
			FuncCode = `FUNC_ADD;
			ALUSrcB = 2'b01;// 00 : RegB, 01 : signImm, 10 : zeroImm, 11 : 0
			branchType = 0;// 00 : BNE, 01 : BEQ, 10 : BGZ, 11 : BLZ
			isLHI = 0;
			MemRead = 1;
			MemWrite = 0;
			MemToReg = 1;
			isJtype = 0; //Jxx case
			isHLT = 0; // hlt case 
			isWWD = 0; // wwd case
			PCALUtype = 2'bz; //00 : branch,  01: JMP JAL, 10: JPR JRL -> Jxx case
			PCWriteCond = 0;
			RegWritePort = 2'b00; // 00: rt, 01: rd, 10: $2 -> JRL case
		end	  
		`SWD_OP	: begin
			regWrite = 0;
			FuncCode = `FUNC_ADD;
			ALUSrcB = 2'b01;// 00 : RegB, 01 : signImm, 10 : zeroImm, 11 : 0
			branchType = 0;// 00 : BNE, 01 : BEQ, 10 : BGZ, 11 : BLZ
			isLHI = 0;
			MemRead = 0;
			MemWrite = 1;
			MemToReg = 0;
			isJtype = 0; //Jxx case
			isHLT = 0; // hlt case 
			isWWD = 0; // wwd case
			PCALUtype = 2'bz; //00 : branch,  01: JMP JAL, 10: JPR JRL -> Jxx case
			PCWriteCond = 0;
			RegWritePort = 2'b00; // 00: rt, 01: rd, 10: $2 -> JRL case
		end
		`BNE_OP	: begin
			regWrite = 0;
			FuncCode = `FUNC_SUB;
			ALUSrcB = 2'b00;// 00 : RegB, 01 : signImm, 10 : zeroImm, 11 : 0
			branchType = 2'b00;// 00 : BNE, 01 : BEQ, 10 : BGZ, 11 : BLZ
			isLHI = 0;
			MemRead = 0;
			MemWrite = 0;
			MemToReg = 0;
			isJtype = 0; //Jxx case
			isHLT = 0; // hlt case 
			isWWD = 0; // wwd case
			PCALUtype = 2'b00; //00 : branch,  01: JMP JAL, 10: JPR JRL -> Jxx case
			PCWriteCond = 1;
			RegWritePort = 0; // 00: rt, 01: rd, 10: $2 -> JRL case
		end
		`BEQ_OP	: begin
			regWrite = 0;
			FuncCode = `FUNC_SUB;
			ALUSrcB = 2'b00;// 00 : RegB, 01 : signImm, 10 : zeroImm, 11 : 0
			branchType = 2'b01;// 00 : BNE, 01 : BEQ, 10 : BGZ, 11 : BLZ
			isLHI = 0;
			MemRead = 0;
			MemWrite = 0;
			MemToReg = 0;
			isJtype = 0; //Jxx case
			isHLT = 0; // hlt case 
			isWWD = 0; // wwd case
			PCALUtype = 2'b00; //00 : branch,  01: JMP JAL, 10: JPR JRL -> Jxx case
			PCWriteCond = 1;
			RegWritePort = 0; // 00: rt, 01: rd, 10: $2 -> JRL case
		end
		`BGZ_OP	: begin
			regWrite = 0;
			FuncCode = `FUNC_SUB;
			ALUSrcB = 2'b11;// 00 : RegB, 01 : signImm, 10 : zeroImm, 11 : 0
			branchType = 2'b10;// 00 : BNE, 01 : BEQ, 10 : BGZ, 11 : BLZ
			isLHI = 0;
			MemRead = 0;
			MemWrite = 0;
			MemToReg = 0;
			isJtype = 0; //Jxx case
			isHLT = 0; // hlt case 
			isWWD = 0; // wwd case
			PCALUtype = 2'b00; //00 : branch,  01: JMP JAL, 10: JPR JRL -> Jxx case
			PCWriteCond = 1;
			RegWritePort = 0; // 00: rt, 01: rd, 10: $2 -> JRL case
		end
		`BLZ_OP	: begin
			regWrite = 0;
			FuncCode = `FUNC_SUB;
			ALUSrcB = 2'b11;// 00 : RegB, 01 : signImm, 10 : zeroImm, 11 : 0
			branchType = 2'b11;// 00 : BNE, 01 : BEQ, 10 : BGZ, 11 : BLZ
			isLHI = 0;
			MemRead = 0;
			MemWrite = 0;
			MemToReg = 0;
			isJtype = 0; //Jxx case
			isHLT = 0; // hlt case 
			isWWD = 0; // wwd case
			PCALUtype = 2'b00; //00 : branch,  01: JMP JAL, 10: JPR JRL -> Jxx case
			PCWriteCond = 1;
			RegWritePort = 0; // 00: rt, 01: rd, 10: $2 -> JRL case
		end
		`JMP_OP	: begin
			regWrite = 0;
			FuncCode = 0;
			ALUSrcB = 0;// 00 : RegB, 01 : signImm, 10 : zeroImm, 11 : 0
			branchType = 0;// 00 : BNE, 01 : BEQ, 10 : BGZ, 11 : BLZ
			isLHI = 0;
			MemRead = 0;
			MemWrite = 0;
			MemToReg = 0;
			isJtype = 1; //Jxx case
			isHLT = 0; // hlt case 
			isWWD = 0; // wwd case
			PCALUtype = 2'b01; //00 : branch,  01: JMP JAL, 10: JPR JRL -> Jxx case
			PCWriteCond = 0;
			RegWritePort = 0; // 00: rt, 01: rd, 10: $2 -> JRL case
		end
		`JAL_OP	: begin
			regWrite = 1;
			FuncCode = 0;
			ALUSrcB = 0;// 00 : RegB, 01 : signImm, 10 : zeroImm, 11 : 0
			branchType = 0;// 00 : BNE, 01 : BEQ, 10 : BGZ, 11 : BLZ
			isLHI = 0;
			MemRead = 0;
			MemWrite = 0;
			MemToReg = 0;
			isJtype = 1; //Jxx case
			isHLT = 0; // hlt case 
			isWWD = 0; // wwd case
			PCALUtype = 2'b01; //00 : branch,  01: JMP JAL, 10: JPR JRL -> Jxx case
			PCWriteCond = 0;
			RegWritePort = 2'b10; // 00: rt, 01: rd, 10: $2 -> JRL, JAL case
		end
		
		endcase


	end


endmodule
