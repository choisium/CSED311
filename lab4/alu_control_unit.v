`include "opcodes.v"

module alu_control_unit(funct, opcode, ALUOp, clk, funcCode, branchType);
  input ALUOp;
  input clk;
  input [5:0] funct;
  input [3:0] opcode;

  output reg [3:0] funcCode;
  output reg [1:0] branchType;

   //TODO: implement ALU control unit
  
always @(*) begin
    if(!ALUOp) begin // common operation
        funcCode = `FUNC_ADD;
        branchType = 0;
    end
    else begin // individual operations
       case (opcode)
            `ALU_OP: begin
                case(funct)
                    `INST_FUNC_JPR: funcCode = `FUNC_ID1; // pc <- rs
                    `INST_FUNC_JRL: funcCode = `FUNC_ID1; // pc <- rs
                    `INST_FUNC_WWD: funcCode = `FUNC_ID1; // outputport <- rs
                    default: funcCode = funct[3:0];
                endcase
            end
            `ADI_OP: funcCode = `FUNC_ADD;
            `ORI_OP: funcCode = `FUNC_ORR;
            `LHI_OP: funcCode = `FUNC_ID2; // immediate : alu_input_2
            `BNE_OP, `BEQ_OP ,`BGZ_OP, `BLZ_OP: begin 
                funcCode = `FUNC_Bxx;
                branchType = opcode[1:0]; //branch type for bne = 0, beq = 1, bgz = 2, blz = 3
            end
            default: funcCode = 4'd15; // no use
        endcase 
    end
end

endmodule