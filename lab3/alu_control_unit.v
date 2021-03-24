`include "opcodes.v"

module alu_control_unit (instr, alu_func_code);
input [`WORD_SIZE-1:0] instr;
output reg [3:0] alu_func_code;

wire [3:0] opcode;
assign opcode = instr[15:12];
wire [5:0] func_code;
assign func_code = instr[5:0];


always @(*) begin
    case (opcode)
        `ALU_OP: begin
            case(func_code)
                `INST_FUNC_JPR: alu_func_code = `FUNC_IP1; // pc <- rs
                `INST_FUNC_JRL: alu_func_code = `FUNC_IP1; // pc <- rs
                default: alu_func_code = func_code[3:0];
            endcase
        end
        `ADI_OP: begin
            alu_func_code = `FUNC_ADD;
        end
        `ORI_OP: begin
            alu_func_code = `FUNC_ORR;
        end
        `LHI_OP: begin // immediate : alu_input_2
            alu_func_code = `FUNC_IP2;
        end
        `LWD_OP: begin
            alu_func_code = `FUNC_ADD;
        end
        `SWD_OP: begin
            alu_func_code = `FUNC_ADD;
        end
        `BNE_OP: begin // Zero if (input1 != input2)
            alu_func_code = `FUNC_BNE;
        end
        `BEQ_OP: begin // Zero if (input1 == input2)
            alu_func_code = `FUNC_SUB;
        end
        `BGZ_OP: begin // Zero if (input1 != 0 and positive)
            alu_func_code = `FUNC_BGZ;
        end
        `BLZ_OP: begin // Zero if (input1 is negative)
            alu_func_code = `FUNC_BLZ;
        end

   	    default: begin      // Don't use ALU
            alu_func_code = 4'd15;
	    end
    endcase
end


endmodule