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
        `ADI_OP: alu_func_code = `FUNC_ADD;
        `ORI_OP: alu_func_code = `FUNC_ORR;
        `LHI_OP: alu_func_code = `FUNC_IP2; // immediate : alu_input_2
        `LWD_OP: alu_func_code = `FUNC_ADD;
        `SWD_OP: alu_func_code = `FUNC_ADD;
        `BNE_OP: alu_func_code = `FUNC_BNE; // Zero if (input1 != input2)
        `BEQ_OP: alu_func_code = `FUNC_SUB; // Zero if (input1 == input2)
        `BGZ_OP: alu_func_code = `FUNC_BGZ; // Zero if (input1 != 0 and positive)
        `BLZ_OP: alu_func_code = `FUNC_BLZ; // Zero if (input1 is negative)
        default: alu_func_code = 4'd15;     // Don't use ALU
    endcase
end


endmodule