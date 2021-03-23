`include "opcodes.v"

module immediate_generator (instr, immediate);
input [`WORD_SIZE-1:0] instr;
output reg [`WORD_SIZE-1:0] immediate;

wire [3:0] opcode;
assign opcode = instr[15:12];
wire [7:0] imm;
assign imm = instr[7:0];

always @(*) begin
    case (opcode)
        `ADI_OP: immediate <= {{8{imm[7]}}, imm[7:0]};
        `ORI_OP: immediate <= {8'b0, imm[7:0]};
        `LHI_OP: immediate <= {imm[7:0], 8'b0};
        `LWD_OP: immediate <= {{8{imm[7]}}, imm[7:0]};
        `SWD_OP: immediate <= {{8{imm[7]}}, imm[7:0]};
        `BNE_OP: immediate <= {{8{imm[7]}}, imm[7:0]};
        `BEQ_OP: immediate <= {{8{imm[7]}}, imm[7:0]};
        `BGZ_OP: immediate <= {{8{imm[7]}}, imm[7:0]};
        `BLZ_OP: immediate <= {{8{imm[7]}}, imm[7:0]};
        default: immediate <= 16'b0; // not happen
    endcase
end

endmodule


