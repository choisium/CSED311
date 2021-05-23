`include "opcodes.v" 

module ALU (inputA, inputB, FuncCode, branchType, isLHI, ALUout, branchCond);
	input [`WORD_SIZE-1:0] inputA;
	input [`WORD_SIZE-1:0] inputB;
	input [2:0] FuncCode;
	input [1:0] branchType; // 00 : BNE, 01 : BEQ, 10 : BGZ, 11 : BLZ
	input isLHI; // 0: non- LHI, 1 : LHI
	output [`WORD_SIZE-1:0] ALUout;
	output branchCond; // 0 : not satisfy branch condition, 1 : satisfy

	reg [`WORD_SIZE-1:0] ALUout;
	reg branchCond;
	
	always @(*) begin

	case(FuncCode)
	`FUNC_ADD: begin
		ALUout = inputA + inputB;
	end
	`FUNC_SUB: begin
		ALUout = inputA - inputB;
		case(branchType)
			2'b00: begin
			branchCond = (ALUout != 0);		
			end
			2'b01: begin
			branchCond = (ALUout == 0);
			end
			2'b10: begin //BGZ
			branchCond = (ALUout[`WORD_SIZE-1]==0 && ALUout != 0);
			end
			2'b11: begin //BLZ
			branchCond = (ALUout[`WORD_SIZE-1]==1);
			end
		endcase
	end				 
	`FUNC_AND: begin
		ALUout = inputA & inputB;	end
	`FUNC_ORR: begin
		ALUout = inputA | inputB;
	end						    
	`FUNC_NOT: begin
		ALUout = ~inputA;
	end
	`FUNC_TCP: begin
		ALUout = ~inputA + 1;
	end		
	`FUNC_SHL: begin
		ALUout = inputA << 1;
	end
	`FUNC_SHR: begin
		ALUout = {inputA[15], inputA[15:1]};
	end
	endcase
	
	if (isLHI) begin
		ALUout = {inputB[7:0], {8{1'b0}}};
	end
	end
	

endmodule



module pcALU (inputA, signImm, target, PCALUtype, PCtarget, branchCond);

	input [`WORD_SIZE-1:0] inputA;
	input [`WORD_SIZE-1:0] signImm;
	input [11:0] target;
	input [1:0] PCALUtype;
	input branchCond;
	output reg[`WORD_SIZE-1:0] PCtarget;

	always @(*) begin
		case(PCALUtype)
			2'b00: begin // branch : (PC+1) + signImm
				if(branchCond) PCtarget = inputA + signImm;
				else PCtarget = inputA;
			end
			2'b01: begin // JMP, JAL
				PCtarget = {inputA[15:12],target[11:0]};
			end
			2'b10: begin // JPR, JRL
				PCtarget = inputA;
			end
		endcase
	end

endmodule
